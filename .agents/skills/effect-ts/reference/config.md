# Configuration Patterns

This document covers how to load typed configuration in Effect services. The official Effect docs are at <https://effect.website/docs/configuration/>.

## Config Module Basics

Use `Config` from `effect` for typed environment configuration. Each config value has a type and can be composed, defaulted, or made optional.

```ts
import { Config } from "effect"

// Required config
const port = Config.integer("PORT")

// With default
const port = Config.integer("PORT").pipe(Config.withDefault(3000))

// Optional
const flag = Config.boolean("FEATURE_FLAG").pipe(Config.option)

// With validation
const url = Config.string("URL").pipe(Config.withDefault("http://localhost:3000"))
```

### Composite Config with Config.all

```ts
const appConfig = Config.all({
  port: Config.integer("PORT").pipe(Config.withDefault(3000)),
  publicUrl: Config.string("PUBLIC_URL").pipe(Config.withDefault("http://localhost:3000")),
  stage: Config.string("STAGE").pipe(Config.withDefault("development")),
})
```

### Providing Config in Tests

Override config values with `ConfigProvider` layers:

```ts
import { ConfigProvider, Layer } from "effect"

const testConfigLayer = ConfigProvider.layer(
  ConfigProvider.fromUnknown({ PORT: 8080, STAGE: "test" }),
)

const testLayer = MyService.defaultLayer.pipe(
  Layer.provide(testConfigLayer),
)
```

## ConfigService Custom Factory

The opencode codebase has a custom `ConfigService` factory (`packages/opencode/src/effect/config-service.ts`) that wraps `Config.all` into a `Context.Service`. This lets config be yielded as a typed service instead of raw `Config` values.

### Factory Definition

```ts
// Example shape (simplified from packages/opencode/src/effect/config-service.ts)
export const Service =
  <Self>() =>
  <const Id extends string, const Fields extends ConfigMap>(id: Id, fields: Fields) => {
    class ConfigTag extends Context.Service<Self, Shape<Fields>>()(id) {
      static layer(input: Shape<Fields>) {
        return Layer.succeed(this, this.of(input))
      }
      static get defaultLayer() {
        return Layer.effect(this, Effect.gen(function* () {
          const config = yield* Config.all(fields)
          return this.of(config)
        }))
      }
    }
    return ConfigTag
  }
```

### Usage: RuntimeFlags

```ts
// packages/opencode/src/effect/runtime-flags.ts
export class Service extends ConfigService.Service<Service>()("@opencode/RuntimeFlags", {
  autoShare: Config.boolean("OPENCODE_AUTO_SHARE").pipe(Config.withDefault(false)),
  pure: Config.boolean("OPENCODE_PURE").pipe(Config.withDefault(false)),
  disableDefaultPlugins: Config.boolean("OPENCODE_DISABLE_DEFAULT_PLUGINS").pipe(Config.withDefault(false)),
}) {}
```

Consumers yield `RuntimeFlags.Service` and get typed access to all flags:

```ts
const flags = yield* RuntimeFlags.Service
if (flags.pure) { /* ... */ }
```

### Test Layer Overrides

```ts
// Override specific flags in tests via layer succeed
export const layerWith = (overrides: Partial<typeof Service.Type>) =>
  Layer.provideMerge(
    Service.defaultLayer,
    Layer.succeed(Service, Service.of({ ...defaults, ...overrides })),
  )

// Or with explicit values
const flagLayer = Service.layer({ autoShare: false, pure: true })
```

### ConfigProvider for Zero-Env Tests

```ts
const emptyConfigLayer = Service.defaultLayer.pipe(
  Layer.provide(ConfigProvider.layer(ConfigProvider.fromUnknown({}))),
  Layer.orDie,
)
```

## Config.succeed — Inline Constants

When Layer construction needs config values that aren't environment-driven, use `Config.succeed`:

```ts
const config = Config.all({
  stage: Config.succeed(Resource.App.stage),
  publicUrl: Config.string("PUBLIC_URL").pipe(Config.withDefault("http://localhost:3000")),
})
```
