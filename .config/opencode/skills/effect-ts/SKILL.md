---
name: effect-ts
description: 'Guidelines and patterns for writing Effect-TS services, layers, and runtime code. Covers service definition patterns, naming conventions, error handling, tracing, layer composition, and anti-patterns to avoid.'
---

# Effect-TS Skill

Guidelines and patterns for writing Effect-TS v4 beta services, layers, and runtime code in this project.

## Version Baseline

This project targets **Effect v4 beta** (`effect@4.0.0-beta.x`). Use v4 APIs and imports:

- `Context.Service` is available and is the preferred service-tag API.
- HTTP platform modules live under `effect/unstable/http`.
- Do not add `@effect/platform` for generic HTTP client code; v4 moved these APIs into `effect`.
- Add platform-specific packages only when needed for platform runtimes or services, e.g. `@effect/platform-bun` or `@effect/platform-node`.

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
```

Keep these sections in the same file unless Schema definitions are shared across modules. Extract schemas to a shared file only when consumed by multiple services.

## Service Definition

### Primary Pattern: `Context.Service` with explicit `Layer.effect`

This is the default pattern. It makes the dependency signature visible on the layer type, supports test substitution, and keeps the contract as a standalone `Interface` type that other modules can reference.

```ts
export namespace MyFeature {
  // 1. Contract
  export interface Interface {
    readonly list: () => Effect.Effect<Item[], MyError>
    readonly create: (input: CreateInput) => Effect.Effect<Item, MyError>
  }

  // 2. Service tag
  export class Service extends Context.Service<Service, Interface>()("my-app/MyFeature") {}

  // 3. Layer — exposes dependency requirements in its type
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

  // 4. Fully-wired layer
  export const defaultLayer = layer.pipe(
    Layer.provide(Database.defaultLayer),
    Layer.provide(FetchHttpClient.layer),
  )
}
```

**`Context.Service` advantages:**
- `Service.of({ ... })` — type-safe construction that validates against the `Interface`
- `yield* Service` — direct access in effect generators
- `Context.Service.Shape<typeof Service>` — extract the interface type from the service class

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

- Namespace name: noun in PascalCase (`Filesystem`, `Auth`, `Project`).
- Service class: always named `Service` inside the namespace.
- Service key: kebab-case with app prefix and path to the service file, double-quoted.
  - `"my-app/db/Database"`, `"my-app/auth/Auth"`, `"@my-app/ACP/Service"`
- Layer exports:
  - `layer` — the base layer with exposed dependency requirements
  - `defaultLayer` — fully wired, all dependencies provided
  - `layerNoDeps` — same as `layer`, used when you ship both wired and unwired variants
  - Descriptive suffixes for variants: `layerTest`, `layerConfig`

## Error Handling

Define domain errors as `Schema.TaggedErrorClass`:

```ts
export class MyError extends Schema.TaggedErrorClass<MyError>()("MyError", {
  message: Schema.String,
  cause: Schema.optional(Schema.Defect),
}) {
  // Optional: custom message formatting
  override get message(): string {
    return `[MyError] ${this.message}`
  }

  // Optional: static factory for wrapping external errors
  static fromCause(input: { message: string; cause: unknown }): MyError {
    return new MyError({ message: input.message, cause: new Schema.Defect(input.cause) })
  }
}
```

Map low-level exceptions to domain errors with `Effect.catchAll` or `Effect.mapError`, never with `try/catch`:

```ts
yield* fs
  .readFile(path)
  .pipe(Effect.mapError((err) => new MyError({ message: "Read failed", cause: err })))

// Or when catching an entire operation:
yield* http.execute(request).pipe(
  Effect.catchAll((error) =>
    Effect.fail(new MyError({ message: "Request failed", cause: error })),
  ),
)
```

Use `Effect.catchAll` with `Effect.fail` (not `Effect.logError` + `Effect.succeed(null)`) so callers get typed errors rather than null checks. The only valid use of a null return is when absence is a valid outcome (e.g., "no excerpts found"), not when an error occurred.

## Schema

Use Effect Schema as the default boundary for validation, normalization, and object parsing.

### Named Structs

```ts
export const Item = Schema.Struct({
  id: Schema.String,
  title: Schema.String,
  createdAt: Schema.DateTimeUtc,
})
export type Item = typeof Item.Type
```

### Branded IDs

```ts
export const ID = Schema.String.pipe(Schema.brand("ItemID"))
export type ID = Schema.Schema.Type<typeof ID>

export const OrgID = Schema.String.pipe(Schema.brand("OrgID"))
export const AccessToken = Schema.String.pipe(Schema.brand("AccessToken"))
```

### Class-Based Schemas

Use `Schema.Class` when a schema needs attached methods:

```ts
export class Info extends Schema.Class<Info>("ModelV2.Info")({
  id: ID,
  name: Schema.String,
  enabled: Schema.Boolean,
  status: Schema.Literals(["alpha", "beta", "deprecated", "active"]),
}) {
  static empty(id: ID): Info {
    return new Info({ id, name: "", enabled: false, status: "active" })
  }
}
```

### Tagged Unions (Non-Error)

```ts
export class PollSuccess extends Schema.TaggedClass<PollSuccess>()("PollSuccess", {
  email: Schema.String,
}) {}
export class PollPending extends Schema.TaggedClass<PollPending>()("PollPending", {}) {}
export class PollError extends Schema.TaggedClass<PollError>()("PollError", {
  cause: Schema.Defect,
}) {}
export const PollResult = Schema.Union([PollSuccess, PollPending, PollError])
```

### Enum-Like Unions

```ts
export const Effect = Schema.Literals(["allow", "deny"]).annotate({ identifier: "Policy.Effect" })
export type Effect = typeof Effect.Type
```

### Decoding Variants

```ts
// Effectful — fails into error channel
Schema.decodeUnknownEffect(Message)(input)

// Option-based — returns Option.none() on failure, no error channel
Schema.decodeUnknownOption(Info)(input, { errors: "all", onExcessProperty: "ignore" })

// Sync — throws on failure, use only at startup boundaries
const decoded = Schema.decodeUnknownSync(Config)(raw)
```

Prefer `Schema.decodeUnknownOption` for optional config parsing and `Schema.decodeUnknownEffect` for runtime data boundaries. Use `Schema.decodeUnknownSync` only at process startup where failure should crash.

### Encoding

```ts
const encoded = Schema.encodeSync(Message)(message)  // throws on failure
```

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

// Build the request with piped modifiers
const response = yield* httpOk.execute(
  HttpClientRequest.post(`${baseURL}/v1/endpoint`).pipe(
    HttpClientRequest.acceptJson,
    HttpClientRequest.setHeaders({
      "x-api-key": apiKey,
    }),
    HttpClientRequest.bodyJson({
      urls: [url],
      options: { full: false },
    }),
  ),
)

// Decode the response body through a Schema
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

**Retry wrapper** for transient network errors:

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

**Providing the HTTP client layer:**

```ts
export const defaultLayer = layer.pipe(
  Layer.provide(FetchHttpClient.layer),
)
```

## Tracing

Wrap every exported service method with `Effect.fn` and a qualified name:

```ts
const list = Effect.fn("MyFeature.list")(function* () {
  // ...
})
```

For effects that don't need tracing (internal helpers, one-liners), use bare `Effect.gen` or inline effects.

## Layer Composition

### Composition Operators

`Layer.provide` — feeds upstream layer outputs into the target, hiding the upstream from the result type:

```ts
// Database.defaultLayer's output is consumed; only Session.layer remains exposed
export const defaultLayer = sessionLayer.pipe(
  Layer.provide(Database.defaultLayer),
  Layer.provide(Projector.defaultLayer),
)
```

`Layer.provideMerge` — feeds upstream layer outputs into the target AND includes them in the result:

```ts
// Both Catalog and Plugin remain exposed in the output type
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
  File.defaultLayer,
  // ... all other services
).pipe(Layer.provideMerge(Observability.layer))
```

### Pattern: Two Variant Layers (Wired + Unwired)

```ts
// Unwired — dependencies are visible in the type
export const layer = Layer.effect(Service, Effect.gen(function* () {
  const sql = yield* SqlClient.Service
  // ...
}))

// Wired — dependencies resolved, clean type for consumers
export const defaultLayer = layer.pipe(
  Layer.provide(SqlClientLayer),
)
```

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

## Anti-Patterns to Avoid

- Do not swallow errors with `catchAll` converting to `null` — use typed errors via `Effect.fail` with `Schema.TaggedErrorClass`
- Do not use `client.post(url, { body, headers })` — use the `HttpClientRequest` builder pattern
- Do not null-guard every step of an HTTP flow; compose it as a single effect pipeline
- Do not use `Effect.Tag` directly — prefer `Context.Service` (or `Effect.Service` for simple cases)
- Do not use `any` type; rely on type inference
- Do not use `try/catch` for control flow; use Effect error channels
- Do not hand-roll validation or parsing when Schema can represent the boundary
- Do not destructure unnecessarily; use dot notation to preserve context
- Do not expose `Layer` construction details outside the service module
- Do not add convenience exports (`export const list = () => Service.use(...)`) — callers should `yield* Service` directly

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

## Reference Documentation

The canonical documentation lives at <https://effect.website/docs>. Key sections relevant to this project:

| Skill Section               | Official Docs                                                                                                                                                                                                                                                                                                                                                                                      |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Service definition & layers | [Managing Services](https://effect.website/docs/requirements-management/services/), [Managing Layers](https://effect.website/docs/requirements-management/layers/)                                                                                                                                                                                                                                 |
| Error handling              | [Expected Errors](https://effect.website/docs/error-management/expected-errors/), [Unexpected Errors](https://effect.website/docs/error-management/unexpected-errors/), [Retrying](https://effect.website/docs/error-management/retrying/), [Fallback](https://effect.website/docs/error-management/fallback/), [Yieldable Errors](https://effect.website/docs/error-management/yieldable-errors/) |
| Schema validation           | [Introduction to Effect Schema](https://effect.website/docs/schema/introduction/), [Basic Usage](https://effect.website/docs/schema/basic-usage/), [Transformations](https://effect.website/docs/schema/transformations/), [Filters](https://effect.website/docs/schema/filters/)                                                                                                                  |
| Tracing                     | [Tracing in Effect](https://effect.website/docs/observability/tracing/)                                                                                                                                                                                                                                                                                                                            |
| Runtime                     | [Introduction to Runtime](https://effect.website/docs/runtime/)                                                                                                                                                                                                                                                                                                                                    |
| Generators / control flow   | [Using Generators](https://effect.website/docs/getting-started/using-generators/), [Control Flow Operators](https://effect.website/docs/getting-started/control-flow/)                                                                                                                                                                                                                             |

**Topics not covered in this skill** — refer to the official docs when needed:

- [Concurrency](https://effect.website/docs/concurrency/basic-concurrency/) — fibers, queues, semaphores, pubsub
- [Streams](https://effect.website/docs/stream/introduction/) — composable, push-based data streaming
- [Scheduling](https://effect.website/docs/scheduling/introduction/) — cron, repetition, schedule combinators
- [State Management](https://effect.website/docs/state-management/ref/) — Ref, SubscriptionRef, SynchronizedRef
- [Resource Management](https://effect.website/docs/resource-management/introduction/) — Scope, safe acquisition/release
- [Observability](https://effect.website/docs/observability/logging/) — logging, metrics, supervisors
- [Caching](https://effect.website/docs/caching/cache/) — Cache, Caching Effects
- [Testing](https://effect.website/docs/testing/testclock/) — TestClock, controlled time in tests
- [Platform](https://effect.website/docs/platform/introduction/) — FileSystem, Command, Path, Terminal, KeyValueStore
- [Configuration](https://effect.website/docs/configuration/) — typed config loading with providers
