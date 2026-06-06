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
