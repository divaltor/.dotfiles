---
name: effect-ts
description: 'Guidelines and patterns for writing Effect-TS services, layers, and runtime code. Covers service definition patterns, naming conventions, error handling, tracing, layer composition, and anti-patterns to avoid.'
---

# Effect-TS Skill

Guidelines and patterns for writing Effect-TS services, layers, and runtime code in this project.

## Service Definition

Default to the bundled `Effect.Service` API for self-contained services. Split into `Interface` + `Effect.Tag` + explicit `Layer.effect` only when the service has external context dependencies or needs swappable implementations.

### Default Pattern: Bundled `Effect.Service`

Use this when the service builds itself without pulling other services from context.

```ts
export namespace MyFeature {
  export class Service extends Effect.Service<Service>()('my-app/MyFeature', {
    effect: Effect.gen(function* () {
      // Self-contained setup (no yield* OtherService)
      const db = yield* createDatabase

      const list = Effect.fn('MyFeature.list')(function* () {
        // ...
      })

      return { list }
    })
  }) {}

  // Convenience exports delegate to Service.use
  export const list = () => Service.use((s) => s.list())
}
```

### Advanced Pattern: Split Definition

Use this when the service depends on other context services or when you need explicit dependency tracking and test substitution.

```ts
export namespace MyFeature {
  // 1. Contract
  export interface Interface {
    readonly list: () => Effect.Effect<Item[]>
  }

  // 2. Tag only
  export class Service extends Effect.Tag('my-app/MyFeature')<Service, Interface>() {}

  // 3. Explicit construction recipe with dependency signature
  export const layer = Layer.effect(
    Service,
    Effect.gen(function* () {
      const dep = yield* OtherService.Service

      const list = Effect.fn('MyFeature.list')(function* () {
        // ...
      })

      return { list } satisfies Interface
    })
  )

  // 4. Convenience exports
  export const list = () => Effect.flatMap(Service, (s) => s.list())
}
```

**Why split?**

- The layer type shows exactly which upstream services it requires.
- You can swap the implementation in tests without changing the contract.
- `defaultLayer` pipelines make the full dependency tree visible.
- `Interface` is a standalone type other modules can reference.

## Naming Conventions

- Namespace name: noun in PascalCase (e.g., `Project`, `Auth`, `FileSystem`).
- Service class: always named `Service` inside the namespace.
- Service key: kebab-case with app prefix (e.g., `'rosalind/Project'`, `'my-app/Auth'`).
- Convenience exports: same names as interface methods, no redundant suffixes.
  - Good: `Project.open`, `Project.close`, `Project.config`
  - Bad: `Project.openProject`, `Project.closeProject`, `Project.readConfig`

## Error Handling

Define domain errors as tagged error classes using `Schema.TaggedErrorClass`:

```ts
export class MyError extends Schema.TaggedErrorClass<MyError>()('MyError', {
  message: Schema.String,
  cause: Schema.optional(Schema.Defect)
}) {}
```

Map low-level exceptions to domain errors with `Effect.mapError`:

```ts
yield *
  fs
    .readFile(path)
    .pipe(Effect.mapError((err) => new MyError({ message: 'Read failed', cause: err })))
```

Avoid `try`/`catch`. Use Effect error channels exclusively.

## Schema Validation And Parsing

Use Effect Schema as the default boundary for validation, normalization, and object parsing. Prefer a named schema plus `Schema.decode*`/`Schema.encode*` over ad-hoc trimming, required-field checks, object reconstruction, or manual parsing helpers.

```ts
import { Schema } from 'effect'

const TrimmedString = Schema.transform(Schema.String, Schema.String, {
  decode: (value) => value.trim(),
  encode: (value) => value
})

export const ProfileSchema = Schema.Struct({
  name: TrimmedString.pipe(Schema.nonEmptyString({ message: () => 'Name is required' })),
  port: TrimmedString.pipe(
    Schema.filter((value) => {
      const port = Number(value)
      return Number.isInteger(port) && port >= 1 && port <= 65535
        ? true
        : 'Port must be between 1 and 65535'
    })
  )
})

export const parseProfile = Schema.decodeUnknownEither(ProfileSchema)
```

Prefer this pattern at process, IPC, persistence, form, config, and external-data boundaries. Put schemas near shared contracts when both main and renderer need the same shape, and derive types from schemas with `Schema.Schema.Type<typeof SchemaName>` to keep runtime validation and TypeScript types aligned.

## Tracing

Wrap every exported service method with `Effect.fn` and a qualified name:

```ts
const list = Effect.fn('Project.list')(function* () {
  // ...
})
```

This enables built-in tracing and debugging.

## Layer Composition

Build application runtimes with `ManagedRuntime.make`:

```ts
const runtime = ManagedRuntime.make(Project.Service.Default)

const run = <A, E>(effect: Effect.Effect<A, E, Project.Service>) => runtime.runPromise(effect)
```

For split services with dependencies, compose layers explicitly:

```ts
const runtime = ManagedRuntime.make(Layer.provide(MyFeature.layer, OtherService.layer))
```

Or expose a fully-wired `defaultLayer`:

```ts
export const defaultLayer = layer.pipe(
  Layer.provide(CrossSpawnSpawner.defaultLayer),
  Layer.provide(AppFileSystem.defaultLayer),
  Layer.provide(NodePath.layer)
)
```

## Runtime Helpers

For long-lived services (e.g., Electron main process), create a `ManagedRuntime` once and reuse it. For request-scoped work, prefer `Effect.scoped`.

## Anti-Patterns to Avoid

- Do not split a service (`Interface` + `Tag` + `Layer`) unless it has external dependencies or needs test substitution. Default to `Effect.Service`.
- Do not expose `Layer` construction details outside the service module.
- Do not use `any` type. Rely on type inference.
- Do not use `try`/`catch` for control flow. Use `Effect.catch*` or error channels.
- Do not hand-roll validation, normalization, or object parsing when Effect Schema can represent the boundary.
- Avoid unnecessary destructuring; use dot notation to preserve context.

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
