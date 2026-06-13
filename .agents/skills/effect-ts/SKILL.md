---
name: effect-ts
description: 'Guidelines and patterns for writing Effect-TS v4 beta services, layers, and runtime code. Covers service definition (Context.Service / Effect.Service), schema modeling (Schema.Class / TaggedClass / TaggedErrorClass with getters and methods), API response parsing (HttpClient + schemaBodyJson), error handling, tracing, layer composition, ManagedRuntime, testing with testEffect / Layer.mock / pollWithTimeout, and anti-patterns to avoid.'
---

# Effect-TS Skill

Guidelines and patterns for writing Effect-TS v4 beta services, layers, and runtime code in this project.

## Version Baseline

This project targets **Effect v4 beta** (`effect@4.0.0-beta.x`). Use v4 APIs and imports:

- `Context.Service` is available and is the preferred service-tag API.
- HTTP platform modules live under `effect/unstable/http`.
- Do not add `@effect/platform` for generic HTTP client code; v4 moved these APIs into `effect`.
- Add platform-specific packages only when needed for platform runtimes or services, e.g. `@effect/platform-bun` or `@effect/platform-node`.

### v3 → v4 Breaking Changes

- `Effect.fork` and `Effect.forkDaemon` **do not exist** in v4. Use `Effect.forkIn(scope)` or `Effect.forkScoped` instead.
- `Effect.forkChild` and `Effect.forkDetach` are available but `forkIn` / `forkScoped` are preferred for scoped background work.

## Import Conventions

**Prefer destructured barrel imports from `"effect"`** for application code. Group imports: effect core, then effect unstable modules, then project modules.

```ts
import { Context, Data, Effect, Layer, Option, pipe, Schema } from "effect"
import { FetchHttpClient, HttpClient, HttpClientRequest, HttpClientResponse } from "effect/unstable/http"
import { Foo } from "./foo"
```

**Namespace subpath imports** (`import * as Effect from "effect/Effect"`) appear in lower-level infrastructure packages (databases, process spawners, HTTP recorders). They are acceptable there but should not spread into application-layer service code.

```ts
// Acceptable in infra packages
import * as Context from "effect/Context"
import * as Effect from "effect/Effect"
import * as Layer from "effect/Layer"
```

## Module File Structure

Services follow a consistent per-module layout. A typical service file contains these sections in order:

```ts
// 1. Imports — grouped: effect core, effect unstable/platform modules, project modules
// 2. Schema definitions (IDs, domain shapes, branded types)
// 3. Domain errors (Schema.TaggedErrorClass)
// 4. Interface contract
// 5. Service class (Context.Service)
// 6. Layer (Layer.effect)
// 7. Composition (defaultLayer with Layer.provide / provideMerge)
// 8. LayerNode export (node) — for graph-based wiring
```

Keep these sections in the same file unless Schema definitions are shared across modules. Extract schemas to a shared file only when consumed by multiple services.

### Self-Reexport

Every service file ends with a self-reexport. Do **not** use `export namespace Foo { ... }` for module organization — it prevents tree-shaking and breaks Node's native TypeScript runner.

```ts
// src/foo/foo.ts — sibling file in a multi-sibling directory
export * as Foo from "./foo"

// src/foo/index.ts — single-module directory
export * as Foo from "."
```

Consumers import the namespace projection:

```ts
import { Foo } from "@/foo/foo"
yield* Foo.Service
Foo.layer
Foo.defaultLayer
```

Do not add barrel `index.ts` files in multi-sibling directories — they force every import to evaluate every sibling, which defeats tree-shaking.

## Service Definition

### Primary Pattern: `Context.Service` with explicit `Layer.effect`

This is the default pattern. It makes the dependency signature visible on the layer type, supports test substitution, and keeps the contract as a standalone `Interface` type that other modules can reference.

```ts
export interface Interface {
  readonly list: () => Effect.Effect<Item[], MyError>
  readonly create: (input: CreateInput) => Effect.Effect<Item, MyError>
}

export class Service extends Context.Service<Service, Interface>()("@opencode/MyFeature") {}

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const db = yield* Database.Service
    const http = yield* HttpClient.HttpClient

    const list = Effect.fn("MyFeature.list")(function* () {
      // ...
    })

    const create = Effect.fn("MyFeature.create")(function* (input) {
      // ...
    })

    return Service.of({ list, create })
  }),
)

// LayerNode for graph-based wiring — every service exports a node
export const node = LayerNode.make(layer, [Database.node])

export const defaultLayer = layer.pipe(
  Layer.provide(Database.defaultLayer),
  Layer.provide(FetchHttpClient.layer),
)
```

**`Context.Service` advantages:**
- `Service.of({ ... })` — type-safe construction that validates against the `Interface`
- `yield* Service` — direct access in effect generators
- `Context.Service.Shape<typeof Service>` — extract the interface type from the service class

### LayerNode Export

Every service exports a `node` via `LayerNode.make(layer, [...dependencies])` for graph-based layer wiring. `LayerNode.buildLayer(node)` resolves the full layer tree with cycle detection. This is the sanctioned way to expose dependency structure outside the module — the `node` export is a declarative graph node, not raw layer construction internals.

See [reference/layer-node.md](reference/layer-node.md) for the full LayerNode guide.

### Shortcut: `Effect.Service` for Self-Contained Services

`Effect.Service` is a convenience API that bundles `Context.Tag` creation and layer construction into one declaration. Internally it:

1. Creates a `Context.Tag` sub-type (the class itself)
2. Auto-generates a `Default` static layer from the constructor effect
3. Optionally merges `dependencies` using `Layer.provide` under the hood

```ts
export namespace Prefix {
  export class Service extends Effect.Service<Service>()("my-app/Prefix", {
    sync: () => ({
      prefix: "PRE",
    }),
  }) {}

  // Service.Default — auto-generated: Layer<Service, never, never>
  // Service.Layer — auto-generated without dependencies wired (for testing)
}
```

With dependencies:

```ts
export namespace Logger {
  export class Service extends Effect.Service<Service>()("my-app/Logger", {
    effect: Effect.gen(function* () {
      const { prefix } = yield* Prefix.Service
      const { postfix } = yield* Postfix.Service
      return {
        info: (msg: string) => Effect.sync(() => console.log(`[${prefix}][${msg}][${postfix}]`)),
      }
    }),
    dependencies: [Prefix.Service.Default, Postfix.Service.Default],
  }) {}
}
```

Here `dependencies` is syntactic sugar — internally, `Effect.Service` calls `Layer.provide(Dependency.Default)` on the auto-generated layer for each entry. The resulting `Logger.Service.Default` has type `Layer<Logger.Service, never, never>` (dependencies are already wired).

**Trade-off:** `Effect.Service` hides the layer's dependency signature (it compresses into `never` once wired). Prefer the explicit `Context.Service` + `Layer.effect` pattern when you want the dependency requirements visible on the layer type, or when you need multiple layer variants (e.g. `layerNoDeps` + `layer`).

## Naming Conventions

- Service key: kebab-case with app prefix and path to the service file, double-quoted.
  - `"@opencode/v2/Catalog"`, `"@opencode/SessionPrompt"`, `"my-app/db/Database"`
- Service class: always named `Service`.
- Layer exports:
  - `layer` — the base layer with exposed dependency requirements
  - `defaultLayer` — fully wired, all dependencies provided
  - `layerNoDeps` — same as `layer`, used when you ship both wired and unwired variants
  - Descriptive suffixes for variants: `layerTest`, `layerConfig`
- Node export: `node` — for graph-based wiring (`LayerNode.make(layer, [...deps])`)

## Error Handling

Define domain errors as `Schema.TaggedErrorClass`:

```ts
export class MyError extends Schema.TaggedErrorClass<MyError>()("MyError", {
  message: Schema.String,
  cause: Schema.optional(Schema.Defect),
}) {}
```

In `Effect.gen` / `Effect.fn`, prefer **`yield* new MyError(...)`** over `yield* Effect.fail(new MyError(...))` for direct early-failure branches. Both work identically at runtime, but `yield*` is more concise and reads as a normal control-flow branch:

```ts
// Preferred — reads as a control-flow branch
function* getRecord(id: string) {
  const match = state.get().get(id)
  if (!match) return yield* new MyError({ message: "Not found", cause: undefined })
  return match
}

// Also valid but less concise
yield* Effect.fail(new MyError({ message: "Not found", cause: undefined }))
```

Map low-level exceptions to domain errors with `Effect.catchAll`, `Effect.mapError`, `Effect.catchTag`, or `Effect.catchTags`, never with `try/catch`:

```ts
yield* fs
  .readFile(path)
  .pipe(Effect.mapError((err) => new MyError({ message: "Read failed", cause: err })))

// For tag-specific catch:
yield* operation.pipe(Effect.catchTag("LLM.Error", () => Effect.succeed(fallback)))

// For defect-only catch (bugs, impossible states):
yield* operation.pipe(
  Effect.catchDefect((defect) =>
    defect instanceof SpecificDefect ? Effect.die(handle(defect)) : Effect.die(defect),
  ),
)
```

Use `Effect.catchAll` with `Effect.fail` (not `Effect.logError` + `Effect.succeed(null)`) so callers get typed errors rather than null checks. The only valid use of a null return is when absence is a valid outcome (e.g., "no excerpts found"), not when an error occurred.

Use `Schema.Defect` for unknown cause fields in error types — it carries the raw defect value without asserting a Schema shape.

Export a domain-level `Error` union from service modules:

```ts
export type Error = Storage.NotFoundError | SessionBusyError
```

## Schema

Effect Schema is the default boundary for validation, normalization, and domain modeling (`Schema.Struct`, `Schema.Class`, `Schema.TaggedClass`, `Schema.TaggedErrorClass`, branded IDs, recursive `Schema.suspend`, decode/encode variants, and the `optionalNull` / `withStatics` / `Newtype` utilities).

See [reference/schema.md](reference/schema.md) for the full Schema guide.

## HttpClient

Use `effect/unstable/http` for HTTP requests. Follow the request-builder pattern: construct the request, pipe it through modifiers, then execute.

```ts
import {
  FetchHttpClient,
  HttpClient,
  HttpClientRequest,
  HttpClientResponse,
} from "effect/unstable/http"

const http = yield* HttpClient.HttpClient
const httpOk = HttpClient.filterStatusOk(http)

const response = yield* httpOk.execute(
  HttpClientRequest.post(`${baseURL}/v1/endpoint`).pipe(
    HttpClientRequest.acceptJson,
    HttpClientRequest.setHeaders({ "x-api-key": apiKey }),
    HttpClientRequest.bodyJson({ urls: [url], options: { full: false } }),
  ),
)

const data = yield* HttpClientResponse.schemaBodyJson(MySchema)(response).pipe(
  Effect.catchAll((error) =>
    Effect.fail(new TransportError({ message: "Decode failed", cause: error })),
  ),
)
```

**Key patterns:**
- Import HTTP APIs from `effect/unstable/http`, not `@effect/platform`.
- `HttpClient.filterStatusOk(client)` — wrap the client once; non-2xx responses become typed errors
- `HttpClientRequest.post/get(...)` — start with a request, then pipe through `.acceptJson`, `.setHeaders`, `.bodyJson`, `.bearerToken`, etc.
- `HttpClientResponse.schemaBodyJson(Schema)(response)` — decode through a Schema, returns the typed Schema type
- Use `client.execute(request)` on a filtered client — never call `client.post(url, { body })` directly

**HttpClient Injection.** Provide via `FetchHttpClient.layer`:

```ts
export const defaultLayer = layer.pipe(Layer.provide(FetchHttpClient.layer))
```

Apply retry wrappers at the client level:

```ts
import { Schedule } from "effect"
import { HttpClient } from "effect/unstable/http"

export const withTransientReadRetry = <E, R>(client: HttpClient.HttpClient.With<E, R>) =>
  client.pipe(
    HttpClient.retryTransient({
      retryOn: "errors-and-responses",
      times: 2,
      schedule: Schedule.exponential(200).pipe(Schedule.jittered),
    }),
  )
```

**HTTP Error Boundaries.** Service modules stay HTTP-agnostic — they should not import HTTP status codes, `HttpApiError`, `HttpServerResponse`, or route-specific error schemas. HTTP handlers translate service errors into endpoint-declared public error schemas. Keep mappings inline when they are one-off; extract tiny shared helpers only when the same translation repeats.

## Tracing

Wrap every exported service method with `Effect.fn` and a qualified name:

```ts
const list = Effect.fn("MyFeature.list")(function* () {
  // ...
})
```

For internal helpers that don't need spans, use `Effect.fnUntraced`:

```ts
const loadFromCache = Effect.fnUntraced(function* (key) {
  // ...
})
```

For effects that don't need tracing at all (one-liners, type-only transformations), use bare `Effect.gen` or inline effects.

## Layer Composition

### Composition Operators

`Layer.provide` — feeds upstream layer outputs into the target, hiding the upstream from the result type:

```ts
export const defaultLayer = sessionLayer.pipe(
  Layer.provide(Database.defaultLayer),
  Layer.provide(Projector.defaultLayer),
)
```

`Layer.provideMerge` — feeds upstream layer outputs into the target AND includes them in the result:

```ts
export const locationLayer = layer.pipe(
  Layer.provideMerge(Plugin.locationLayer),
  Layer.provideMerge(Policy.locationLayer),
)
```

`Layer.mergeAll` — combines independent layers into one:

```ts
export const AppLayer = Layer.mergeAll(
  Database.defaultLayer,
  Auth.defaultLayer,
  Config.defaultLayer,
).pipe(Layer.provideMerge(Observability.layer))
```

`Layer.unwrap` — for dynamic layer construction (e.g., loading layers from async config):

```ts
export const layer = Layer.unwrap(
  Effect.gen(function* () {
    const config = yield* Config.string("FEATURE_FLAG")
    if (config === "enabled") return FeatureLayer
    return Layer.empty
  }),
)
```

`Layer.fresh` — ensures a new instance per use, preventing memoized sharing. Used for location-scoped caches.

### Pattern: Two Variant Layers (Wired + Unwired)

```ts
// Unwired — dependencies are visible in the type
export const layer = Layer.effect(Service, Effect.gen(function* () {
  const sql = yield* SqlClient.Service
  // ...
}))

// Wired — dependencies resolved, clean type for consumers
export const defaultLayer = layer.pipe(Layer.provide(SqlClientLayer))
```

## ManagedRuntime

Runtime construction and wrappers — `ManagedRuntime.make` with `memoMap`, `AppRuntime`, `makeRuntime` wrappers, `EffectBridge`, lazy singleton runtimes, and `InstanceState` for per-directory state.

See [reference/runtime.md](reference/runtime.md) for the full Runtime and Bridge guide.

## EffectBridge

When crossing from non-Effect code (callbacks, native APIs, plugin systems) back into Effect, use `EffectBridge` to preserve instance/workspace context. It captures the current fiber's `InstanceRef` and `WorkspaceRef` at the boundary and restores them when the bridge is used.

See [reference/runtime.md](reference/runtime.md) for the full Bridge and InstanceState guide.

## Concurrency & Caching

### Forking Background Work

Use `Effect.forkIn(scope)` to fork background work into a specific scope. Use `Effect.forkScoped` when the fiber should live as long as the current scope.

```ts
yield* backgroundTask.pipe(Effect.forkIn(scope))
yield* Stream.runForEach(s => handle(s)).pipe(Effect.forkScoped)
```

Do **not** use `Effect.fork` or `Effect.forkDaemon` — they don't exist in v4.

### Deduplication with Effect.cached

Use `Effect.cached` when multiple concurrent callers should share one in-flight computation. It memoizes the effect, so subsequent callers get the same result without re-executing.

```ts
const adapter = yield* Effect.cached(loadAdapter())
```

Do not hand-roll `Fiber | undefined` or `Promise | undefined` for deduplication.

### Deferred, FiberSet, FiberMap

For coordination patterns, `Deferred` is a one-shot signal, `FiberSet` manages a dynamic pool of concurrent fibers, and `FiberMap` is a keyed variant. See [reference/concurrency.md](reference/concurrency.md).

## Config

Use `Config` from `effect` for typed environment configuration:

```ts
const port = Config.integer("PORT").pipe(Config.withDefault(3000))
const flag = Config.boolean("FEATURE_FLAG").pipe(Config.option)

// Composite config
const config = Config.all({ port, flag, url: Config.string("URL") })
```

For opencode-specific typed config layers, use the `ConfigService` custom factory (`packages/opencode/src/effect/config-service.ts`). See [reference/config.md](reference/config.md) for details.

## Conventions

- Use `Effect.void` instead of `Effect.succeed(undefined)` or `Effect.succeed(void 0)`.
- Prefer `DateTime.nowAsDate` over `new Date(yield* Clock.currentTimeMillis)` when you need a `Date`.
- Prefer `Effect.retry` with `Schedule` combinators over hand-rolled retry loops.
- For background loops, use `Effect.repeat` or `Effect.schedule` with `Effect.forkScoped`.
- Keep parsed objects as Schema class instances throughout the codebase. Convert to plain types only at persistence boundaries.

### Preferred Effect Services

In effectified code, yield existing Effect services instead of dropping to ad hoc platform APIs:

| Instead of | Use |
|---|---|
| `fs/promises` I/O | `FileSystem.FileSystem` (or project's `FSUtil.Service`) |
| `node:child_process` / raw spawn | `ChildProcessSpawner.ChildProcessSpawner` (or project's `AppProcess.Service`) |
| Raw `fetch()` | `HttpClient.HttpClient` |
| `path.join`, `path.resolve` | `Path.Path` |
| `process.env.X` reads in Effect | `Config` module |
| `Date.now()` in generators | `DateTime.nowAsDate` via `Clock` |

## Testing

Effect service tests run inside a per-file `testEffect` runner from `test/lib/effect.ts`. The three variants — `it.effect` (TestClock), `it.live` (real clock), and `it.instance` (live + scoped tempdir + `InstanceRef`) — cover the common shapes. Layer composition uses `Layer.mock` for partial service stubs and small boundary fakes in `test/fake/*` for shared stubs. Synchronization waits on published signals (`pollWithTimeout`, `awaitWithTimeout`, `Deferred`, `SessionStatus.Service`), never on `Effect.sleep` or `setTimeout`.

See [reference/testing.md](reference/testing.md) for the full Testing guide.

## Anti-Patterns to Avoid

- Do not swallow errors with `catchAll` converting to `null` — use typed errors via `Effect.fail` with `Schema.TaggedErrorClass`
- Do not use `client.post(url, { body, headers })` — use the `HttpClientRequest` builder pattern
- Do not null-guard every step of an HTTP flow; compose it as a single effect pipeline
- Do not use `Effect.Tag` directly — prefer `Context.Service` (or `Effect.Service` for simple cases)
- Do not use `any` type; rely on type inference
- Do not use `try/catch` for control flow; use Effect error channels
- Do not hand-roll validation or parsing when Schema can represent the boundary
- Do not destructure unnecessarily; use dot notation to preserve context
- Do not add convenience exports (`export const list = () => Service.use(...)`) — callers should `yield* Service` directly
- Do not use `Effect.fork` or `Effect.forkDaemon` — they don't exist in v4; use `Effect.forkIn(scope)` / `Effect.forkScoped`
- Do not use `Effect.sleep` or `setTimeout` for test synchronization — wait on published signals
- Do not expose raw `Layer` construction internals outside the service module; export a `LayerNode` node instead
- Do not mutate `process.env`, `Flag`, or module globals after services/layers are built

## Reference Documentation

### Skill Reference Files

| File | Covers |
|---|---|
| [reference/schema.md](reference/schema.md) | `Schema.Class`, `Schema.TaggedClass`, `Schema.TaggedErrorClass`, branded IDs, recursive schemas, `Schema.suspend`, `Schema.Defect`, `Schema.Literals`, `Schema.fromJsonString`, decode/encode variants, `optionalNull`, `withStatics`, `Newtype` |
| [reference/runtime.md](reference/runtime.md) | `ManagedRuntime.make`, `memoMap`, `AppRuntime`, `makeRuntime`, lazy singletons, `NodeRuntime.runMain`, `Effect.Service` internals, `EffectBridge`, `InstanceState` |
| [reference/testing.md](reference/testing.md) | `testEffect` runner, `it.effect` / `it.live` / `it.instance`, fixtures, `Layer.mock`, boundary fakes, synchronization, concurrency idioms, failure assertions |
| [reference/concurrency.md](reference/concurrency.md) | `FiberSet`, `FiberMap`, `Deferred`, `Effect.raceFirst`, `Effect.all`, `Effect.forkIn`, `Effect.forkScoped`, `Effect.cached`, `Scope.fork` |
| [reference/layer-node.md](reference/layer-node.md) | `LayerNode.make`, `LayerNode.group`, `LayerNode.buildLayer`, `LayerNode.replace`, cycle detection, graph-based wiring |
| [reference/config.md](reference/config.md) | `Config` module basics, `Config.all`, `Config.option`, `ConfigService` custom factory, `RuntimeFlags` pattern |

### Official Effect Documentation

The canonical documentation lives at <https://effect.website/docs>. Key sections relevant to this project:

| Topic | Official Docs |
|---|---|
| Service definition & layers | [Managing Services](https://effect.website/docs/requirements-management/services/), [Managing Layers](https://effect.website/docs/requirements-management/layers/) |
| Error handling | [Expected Errors](https://effect.website/docs/error-management/expected-errors/), [Unexpected Errors](https://effect.website/docs/error-management/unexpected-errors/), [Retrying](https://effect.website/docs/error-management/retrying/), [Fallback](https://effect.website/docs/error-management/fallback/), [Yieldable Errors](https://effect.website/docs/error-management/yieldable-errors/) |
| Schema basics | [Introduction to Effect Schema](https://effect.website/docs/schema/introduction/), [Basic Usage](https://effect.website/docs/schema/basic-usage/), [Transformations](https://effect.website/docs/schema/transformations/), [Filters](https://effect.website/docs/schema/filters/) |
| Schema.Class / TaggedClass | [Schema Classes](https://effect.website/docs/schema/classes/), [Branded Types](https://effect.website/docs/schema/branded-types/) |
| HttpClient | [HttpClient module](https://effect.website/docs/platform/http-client/), [Request builders](https://effect.website/docs/platform/http-client/#making-requests) |
| Tracing | [Tracing in Effect](https://effect.website/docs/observability/tracing/) |
| Runtime | [Introduction to Runtime](https://effect.website/docs/runtime/) |
| Generators / control flow | [Using Generators](https://effect.website/docs/getting-started/using-generators/), [Control Flow Operators](https://effect.website/docs/getting-started/control-flow/) |
| Testing | [Testing](https://effect.website/docs/testing/overview/) (testEffect runner, TestClock, TestConsole) |
| Configuration | [Configuration](https://effect.website/docs/configuration/) |

**Topics not covered in this skill** — refer to the official docs when needed:

- [Concurrency](https://effect.website/docs/concurrency/basic-concurrency/) — fibers, queues, semaphores, pubsub
- [Streams](https://effect.website/docs/stream/introduction/) — composable, push-based data streaming
- [Scheduling](https://effect.website/docs/scheduling/introduction/) — cron, repetition, schedule combinators
- [State Management](https://effect.website/docs/state-management/ref/) — Ref, SubscriptionRef, SynchronizedRef
- [Resource Management](https://effect.website/docs/resource-management/introduction/) — Scope, safe acquisition/release
- [Observability](https://effect.website/docs/observability/logging/) — logging, metrics, supervisors
- [Caching](https://effect.website/docs/caching/cache/) — Cache, Caching Effects
- [Platform](https://effect.website/docs/platform/introduction/) — FileSystem, Command, Path, Terminal, KeyValueStore
