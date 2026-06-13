## ManagedRuntime

### Creating a Runtime

```ts
import { ManagedRuntime } from "effect"

export const AppRuntime = ManagedRuntime.make(AppLayer, { memoMap })

// Extract the service type for type annotations
export type AppServices = ManagedRuntime.ManagedRuntime.Services<typeof AppRuntime>
```

The `memoMap` option is important — it enables memoization across layers built from the same runtime, avoiding duplicate resource initialization when a layer is used by multiple consumers.

### Runtime Wrappers

Wrap the raw `ManagedRuntime` methods for ergonomic access:

```ts
const rt = ManagedRuntime.make(AppLayer, { memoMap })

export const AppRuntime = {
  runSync: <A, E>(effect: Effect.Effect<A, E, AppServices>) => rt.runSync(effect),
  runPromise: <A, E>(effect: Effect.Effect<A, E, AppServices>) => rt.runPromise(effect),
  runFork: <A, E>(effect: Effect.Effect<A, E, AppServices>) => rt.runFork(effect),
  dispose: () => rt.dispose(),
}
```

### Lazy Singleton Runtime

When runtime creation is expensive and may not always be needed, defer initialization:

```ts
export function makeRuntime<I, S, E>(service: Context.Service<I, S>, layer: Layer.Layer<I, E>) {
  let rt: ManagedRuntime.ManagedRuntime<I, E> | undefined

  const getRuntime = () =>
    (rt ??= ManagedRuntime.make(Layer.provideMerge(layer, Observability.layer), { memoMap }))

  return {
    runSync: <A, Err>(fn: (svc: S) => Effect.Effect<A, Err, I>) =>
      getRuntime().runSync(service.use(fn)),
    runPromise: <A, Err>(fn: (svc: S) => Effect.Effect<A, Err, I>, options?: Effect.RunOptions) =>
      getRuntime().runPromise(service.use(fn), options),
  }
}
```

The first call to `runSync` or `runPromise` triggers runtime construction; subsequent calls reuse the cached instance.

### CLI Entry Point

For CLI tools, use `NodeRuntime.runMain`:

```ts
import { NodeRuntime } from "@effect/platform-node"
import { Command, Effect, Layer } from "effect"

const cli = Command.make("my-app", ...)
const layer = Layer.mergeAll(AppLayer, NodeServices.layer)

Command.run(cli, { version: "1.0.0" }).pipe(
  Effect.provide(layer),
  Effect.scoped,
  NodeRuntime.runMain,
)
```

## Appendix: `Effect.Service` Internals

`Effect.Service<Self>()(key, options)` does the following under the hood:

1. Creates a `Context.Tag` — the class itself becomes yieldable in generators (`yield* Service`)
2. Inspects the `options` object:
   - `sync: () => value` → creates `Layer.sync(Service, value)`
   - `effect: Effect.gen(...)` → creates `Layer.effect(Service, effect)`
   - `scoped: Effect.gen(...)` → creates `Layer.scoped(Service, scoped)`
3. Exposes the auto-generated layer as `Service.Default` (dependencies wired) and `Service.Layer` (dependencies exposed)
4. If `dependencies: [...]` is provided, pipes each dependency through `Layer.provide`:

```ts
// Internal equivalent:
const baseLayer = Layer.effect(Service, options.effect)
const wiredLayer = dependencies.reduce(
  (acc, dep) => acc.pipe(Layer.provide(dep)),
  baseLayer,
)
// wiredLayer becomes Service.Default
```

This means `dependencies` is purely syntactic sugar for chained `Layer.provide()` calls — there is no runtime magic, just composition.

## Global memoMap

The opencode codebase shares a single `memoMap` across all runtimes to deduplicate layer instances globally:

```ts
// packages/core/src/effect/memo-map.ts
import { Layer } from "effect"
export const memoMap = Layer.makeMemoMapUnsafe()
```

Every `ManagedRuntime.make` call in the codebase passes `{ memoMap }`. This ensures that services like `Bus`, `Cache`, and `Observability` are created once and shared across all runtimes in the process.

## EffectBridge — Promise/Callback Interop

`EffectBridge` (`packages/opencode/src/effect/bridge.ts`) is the sanctioned helper for crossing from non-Effect code (callbacks, native APIs, plugin systems) back into Effect while preserving instance/workspace context.

### Why It's Needed

When a non-Effect callback (e.g., `@parcel/watcher`, `node-pty`, plugin hooks) needs to run Effect code, it must restore the `InstanceRef` and `WorkspaceRef` that existed when the callback was registered. Without this, code like `Effect.runPromise(someEffect)` runs without instance context and fails on any service that depends on per-directory state.

### How It Works

```ts
import { EffectBridge } from "@/effect/bridge"

// Capture happens inside an Effect fiber (has instance/workspace context)
const bridge = yield* EffectBridge.make()

// Later, from a non-Effect callback:
await bridge.promise(someEffect)   // runs with original instance/workspace context
bridge.fork(someEffect)             // fire-and-forget with restored context
bridge.bind((x) => compute(x))()    // sync binding with restored context
```

Internally, `EffectBridge.make()` captures:
1. The current fiber's `InstanceRef` (per-directory instance identity)
2. The current fiber's `WorkspaceRef` (workspace identity)
3. The fiber context itself

When `bridge.promise(effect)` is called later, it wraps the effect with the captured context before running it.

### When to Use

Use `EffectBridge` for:
- Native callback APIs (`@parcel/watcher`, `node-pty`, `fs.watch`)
- Plugin systems that call back into Effect code
- Any boundary where non-Effect code needs to re-enter Effect with context

Do not use `EffectBridge` for:
- Plain async code that can stay inside an Effect fiber — yield `Effect.promise(...)` instead
- Code that doesn't depend on instance/workspace context
- Test code — use `testEffect` / `it.effect` / `it.instance` instead

## InstanceState — Per-Directory ScopedCache

`InstanceState` (`packages/opencode/src/effect/instance-state.ts`) wraps `ScopedCache` to provide per-directory state with automatic disposal. When two open directories should not share one copy of a service's state, use `InstanceState`.

### When to Use InstanceState

Use `InstanceState` when:
- Two open project directories in the same process should have independent service state
- The state requires cleanup when a directory instance is unloaded (subscriptions, file watchers, connection pools)
- The state has per-instance finalizers (`Effect.addFinalizer`, `Effect.acquireRelease`)

### Pattern

```ts
import { InstanceState } from "@/effect/instance-state"

const stateImpl = Effect.fn("Service.state")(function* () {
  // Subscribe to events — cleaned up when instance is disposed
  const bus = yield* Bus.Service
  yield* bus.subscribeAll().pipe(
    Stream.runForEach((event) => handleEvent(event)),
    Effect.forkScoped,
  )

  // Acquire a resource — released on disposal
  yield* Effect.acquireRelease(openConnection, closeConnection)

  return yield* loadInitialState()
})

// In the layer:
const state = yield* InstanceState.make<MyState>(stateImpl)

// In methods:
const methods = {
  read: (key: string) => Effect.gen(function* () {
    const s = yield* InstanceState.get(state)
    return s.get(key)
  }),
}
```

### Rules

- Do the work directly in the `InstanceState.make(...)` closure — `ScopedCache` handles run-once and concurrent deduplication.
- Do not add ad hoc `started` flags, `ensure()` callbacks, or separate `init()` fibers on top of `InstanceState`.
- Put subscriptions, finalizers, and scoped background work inside the `InstanceState.make(...)` initializer.
- Use `Effect.forkScoped` inside the closure for background stream consumers — the fiber is interrupted when the instance is disposed.
- To make `init()` non-blocking, fork at the caller/bootstrap boundary (e.g., `Effect.forkIn(scope)`), not inside `InstanceState.make(...)`. Forking inside the closure leaves state incomplete.

### InstanceRef & WorkspaceRef

`Context.Reference` values carry instance and workspace identity through the fiber context:

```ts
// packages/opencode/src/effect/instance-ref.ts
export const InstanceRef = Context.Reference<InstanceContext | undefined>(
  "~opencode/InstanceRef",
  { defaultValue: () => undefined },
)
export const WorkspaceRef = Context.Reference<WorkspaceV2.ID | undefined>(
  "~opencode/WorkspaceRef",
  { defaultValue: () => undefined },
)
```

These are set when an instance is loaded and restored by `EffectBridge` when crossing boundaries.

## Configuration

For typed config loading, use `Config` from `effect` directly, or the opencode-specific `ConfigService` custom factory for compile-time-typed config layers. See [reference/config.md](reference/config.md).

For graph-based layer wiring with cycle detection, see [reference/layer-node.md](reference/layer-node.md). For concurrency patterns, see [reference/concurrency.md](reference/concurrency.md).
