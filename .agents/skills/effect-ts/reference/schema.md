## Schema

Use Effect Schema as the default boundary for validation, normalization, and object parsing. Schema is also the foundation for **domain modeling** — define classes for objects that need behavior (methods, getters) or identity (`instanceof`).

### When to Use Which Schema Constructor

| Need | Constructor |
|---|---|
| Pure data shape (DTOs, request bodies, config) | `Schema.Struct({...})` |
| Domain object with behavior, methods, or getters | `Schema.Class<Self>(name)({...})` |
| Discriminated union leaves with `_tag` + `instanceof` | `Schema.TaggedClass<Self>()(name, {...})` |
| Error types needing `instanceof` + `_tag` + yieldable | `Schema.TaggedErrorClass<Self>()(name, {...})` |
| Static helpers on a `Struct` or `Union` | `.pipe(withStatics(...))` |

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
export const ItemID = Schema.String.pipe(Schema.brand("ItemID"))
export type ItemID = Schema.Schema.Type<typeof ItemID>
```

### Schema.Class — Domain Objects with Behavior

`Schema.Class` is the canonical container for parsed objects that need computed getters, instance methods, or normalization. It plays the role of a class but stays in sync with the schema.

#### Use ES6 getters for computed values

Getters attach to every decoded instance automatically and avoid a method-call surface where a property is expected:

```ts
export class Usage extends Schema.Class<Usage>("LLM.Usage")({
  inputTokens: Schema.optional(Schema.Number),
  outputTokens: Schema.optional(Schema.Number),
  reasoningTokens: Schema.optional(Schema.Number),
}) {
  /** outputTokens minus reasoningTokens, clamped to zero */
  get visibleOutputTokens(): number {
    return Math.max(0, (this.outputTokens ?? 0) - (this.reasoningTokens ?? 0))
  }
}
```

Use getters for derived reads only. Do not put side-effecting operations in getters.

#### `static from(input)` — idempotent factory

Every `Schema.Class` instantiated from external data should expose a `static from()` that early-returns if the input is already an instance. The pattern lets callers always pass "data or instance" without losing normalization guarantees:

```ts
export class Usage extends Schema.Class<Usage>("LLM.Usage")({
  // ... fields
}) {
  get visibleOutputTokens(): number { /* ... */ }

  static from(input: UsageInput): Usage {
    return input instanceof Usage ? input : new Usage(input)
  }
}

// Input type accepts instance OR constructor args
export type UsageInput = Usage | ConstructorParameters<typeof Usage>[0]
```

This is critical for event builders, protocol mappers, and any code that normalizes data flowing between subsystems. Consumers call `Usage.from(data)` and always get a canonical `Usage` instance regardless of what they received.

**Opencode reference:** `~/dev/opencode/packages/llm/src/schema/events.ts:L51-L76`

#### Namespace pattern for multiple factories

When a class needs several shorthand constructors (e.g., role-based message builders), use `export namespace ClassName { ... }` immediately after the class to keep the class body minimal:

```ts
export class Message extends Schema.Class<Message>("LLM.Message")({
  id: Schema.optional(Schema.String),
  role: MessageRole,
  content: Schema.Array(ContentPart),
}) {}

export namespace Message {
  // Loose Input type — accepts a string or pre-built parts
  export type Input = Omit<ConstructorParameters<typeof Message>[0], "content"> & {
    readonly content: string | ContentPart | ReadonlyArray<ContentPart>
  }

  // Canonical factory — idempotent, normalizes input
  export const make = (input: Message | Input): Message => {
    if (input instanceof Message) return input
    return new Message({ ...input, content: normalize(input.content) })
  }

  // Shorthand constructors
  export const user = (content: string) => make({ role: "user", content })
  export const assistant = (content: string) => make({ role: "assistant", content })
  export const system = (content: string) => make({ role: "system", content })
}
```

Rules:
- Class body: fields only (no factory logic)
- Namespace: `make()` is the canonical entry point; shorthand constructors delegate to it
- Always use `ConstructorParameters<typeof X>[0]` for the structured `Input` type

**Opencode reference:** `~/dev/opencode/packages/llm/src/schema/messages.ts:L275-L314`

#### Recursive schemas with `Schema.suspend`

For self-referential types (a tweet with `quote: Tweet | null`, a tree with `children: Tree[]`), place `Schema.suspend(() => T)` **inside** a `Schema.Class` field — not at the top level of a `Schema.Struct`:

```ts
// ✅ Correct: suspend inside Schema.Class field
export class Info extends Schema.Class<Info>("Skill.Info")({
  name: Schema.String,
  // ...
}) {}

export class EmbeddedSource extends Schema.Class<EmbeddedSource>("Skill.EmbeddedSource")({
  type: Schema.Literal("embedded"),
  skill: Schema.suspend(() => Info), // forward reference to a Schema.Class
}) {}
```

**Gotcha — `decodeUnknownSync` breaks on recursive schemas.** `Schema.suspend` widens the inferred `DecodingServices` to `unknown`, which is not assignable to `SyncDecodingServices`. Workarounds:

1. **At service boundaries** (preferred): use the Effect-based `Schema.decodeUnknownEffect` or `Schema.decodeUnknownOption` — they have no services constraint
2. **At startup / test boundaries**: cast the schema to `any` at the decode call site (`Schema.decodeUnknownSync(MyRecursiveSchema as any)(raw)`). This is a type-level-only concession; the runtime decoder is unaffected
3. **Direct construction**: `new Foo({...})` validates field-level schemas at construction time without needing `decodeUnknownSync`

**Opencode reference:** `~/dev/opencode/packages/core/src/skill.ts:L24-L27`

### TaggedClass — Discriminated Union Leaves

`Schema.TaggedClass` provides `_tag`, `instanceof`, and a `.make()` factory. Use zero-arg leaves (`{}`) for variants that carry no data:

```ts
export class PollSuccess extends Schema.TaggedClass<PollSuccess>()("PollSuccess", {
  email: Schema.String,
}) {}

export class PollPending extends Schema.TaggedClass<PollPending>()("PollPending", {}) {}
export class PollExpired extends Schema.TaggedClass<PollExpired>()("PollExpired", {}) {}
export class PollError extends Schema.TaggedClass<PollError>()("PollError", {
  cause: Schema.Defect,
}) {}

export const PollResult = Schema.Union([PollSuccess, PollPending, PollExpired, PollError])
```

Consumers narrow with `instanceof`:

```ts
const result = Schema.decodeUnknownSync(PollResult)(raw)
if (result instanceof PollSuccess) { /* result.email is typed */ }
else if (result instanceof PollPending) { /* no fields, just identity */ }
```

For non-`TaggedClass` discriminators (when you need `Schema.Class` behavior **and** a `_tag`), add `Schema.tag("Name")` as a field on a regular `Schema.Class`.

**Opencode reference:** `~/dev/opencode/packages/core/src/account.ts:L84-L100`

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

Prefer `Schema.decodeUnknownOption` for optional config parsing and `Schema.decodeUnknownEffect` for runtime data boundaries. Use `Schema.decodeUnknownSync` only at process startup where failure should crash. For recursive schemas, prefer `decodeUnknownEffect` / `decodeUnknownOption` (see `Schema.suspend` gotcha above).

### Encoding

```ts
const encoded = Schema.encodeSync(Message)(message)  // throws on failure
```

### Schema Utilities

#### `optionalNull` helper

For the common `Schema.optional(Schema.NullOr(X))` pattern, define a tiny helper rather than repeating:

```ts
// In a shared schema-utils file
export const optionalNull = <const S extends Schema.Top>(schema: S) =>
  Schema.optional(Schema.NullOr(schema))

// Usage
quote: optionalNull(FxEmbedTweet),
```

#### `withStatics` helper

Attach static helpers to a `Schema.Struct` or `Schema.Union` after definition (useful when the schema shouldn't be promoted to a class):

```ts
// In a shared schema-utils file
export const withStatics =
  <S extends object, M extends Record<string, unknown>>(methods: (schema: S) => M) =>
  (schema: S): S & M =>
    Object.assign(schema, methods(schema))

// Usage
export const Source = Schema.Union([DirectorySource, UrlSource, EmbeddedSource]).pipe(
  Schema.toTaggedUnion("type"),
  withStatics(() => ({
    equals: (a: Source, b: Source) => a._tag === b._tag && a.url === b.url,
    key: (source: Source) => source.url,
  })),
)
```

**Opencode references:** `~/dev/opencode/packages/llm/src/protocols/shared.ts:L23`, `~/dev/opencode/packages/core/src/schema.ts:L85-L88`
