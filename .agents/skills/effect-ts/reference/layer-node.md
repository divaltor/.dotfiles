# LayerNode — Graph-Based Layer Wiring

`LayerNode` (`packages/core/src/effect/layer-node.ts`) is a graph-based layer composition system used throughout the opencode codebase. Every service exports a `node` that declares its own layer implementation and its dependency nodes.

## Why LayerNode

Direct `Layer.provide` / `Layer.mergeAll` works for simple trees but doesn't scale to large dependency graphs with shared dependencies, optional overrides, and cycle detection. `LayerNode` provides:

- **Declarative dependency graph** — each service declares what it depends on
- **Cycle detection** — `LayerNode.buildLayer` throws with a cycle path if there's a circular dependency
- **Node replacement** — swap out nodes (e.g., mock DB for tests) without changing individual `Layer.provide` chains
- **Group nodes** — bundle multiple independent nodes into one

## Defining a Node

Every service exports a `node` using `LayerNode.make(layer, [...dependencies])`:

```ts
import { LayerNode } from "@opencode-ai/core/effect/layer-node"

export const layer = Layer.effect(Service, Effect.gen(function* () {
  const db = yield* Database.Service
  const events = yield* EventV2.Service
  return Service.of({ /* ... */ })
}))

export const node = LayerNode.make(layer, [Database.node, EventV2.node])
```

The type checker validates that all services required by `layer` are covered by the dependency nodes. If a dependency is missing, you get a compile-time error.

## Group Nodes

Bundle independent nodes into a single unit:

```ts
export const infrastructureNode = LayerNode.group([
  Database.node,
  EventV2.node,
  Projector.node,
])
```

Groups are transparent — they flatten into their constituent layers at build time.

## Building a Layer

`LayerNode.buildLayer(node)` resolves the full dependency graph into a `Layer`:

```ts
export const defaultLayer = LayerNode.buildLayer(App.node)
```

It handles:
1. **Deduplication** — each node is built once, even if referenced by multiple parents
2. **Cycle detection** — throws with a human-readable cycle path (`layer#1 -> layer#3 -> layer#1`)
3. **Group flattening** — group nodes are transparent
4. **Empty nodes** — nodes with no dependencies and no implementation produce `Layer.empty`

## Replacing Nodes

Use `LayerNode.replace(sourceNode, replacementLayer)` to create a replacement pair, then pass replacements to `buildLayer`:

```ts
const replacements = [
  LayerNode.replace(Database.node, testDatabaseLayer),
  LayerNode.replace(EventV2.node, testEventLayer),
]

const testLayer = LayerNode.buildLayer(App.node, { replacements })
```

For replacing a node with another node (preserving its own dependencies):

```ts
LayerNode.replaceWithNode(originalNode, replacementNode)
```

## Full Example

```ts
// database.ts
export const node = LayerNode.make(layer, [])

// event.ts
export const node = LayerNode.make(layer, [])

// catalog.ts
export const layer = Layer.effect(Service, Effect.gen(function* () {
  const db = yield* Database.Service
  const events = yield* EventV2.Service
  return Service.of({ /* ... */ })
}))
export const node = LayerNode.make(layer, [Database.node, EventV2.node])

// auth.ts
export const layer = Layer.effect(Service, Effect.gen(function* () {
  const catalog = yield* Catalog.Service
  return Service.of({ /* ... */ })
}))
export const node = LayerNode.make(layer, [Catalog.node])

// App composition
import { LayerNode } from "@opencode-ai/core/effect/layer-node"

export const AppNode = LayerNode.group([
  Auth.node,
  // ... all top-level services
])

export const AppLayer = LayerNode.buildLayer(AppNode)
```
