# Concurrency & Caching Patterns

This document covers the concurrency primitives and caching patterns used throughout the opencode codebase. The official Effect concurrency docs are at <https://effect.website/docs/concurrency/basic-concurrency/>.

## Forking Background Work

### Primary Pattern: `Effect.forkIn(scope)` / `Effect.forkScoped`

`Effect.forkIn(scope)` forks a fiber into a specific scope. The fiber is interrupted when the scope closes. This is the **replacement for `Effect.fork`** (which doesn't exist in v4).

```ts
// Fork into a specific scope
yield * backgroundTask.pipe(Effect.forkIn(scope, { startImmediately: true }));

// Fork into the current scope (fiber lives as long as current scope)
yield *
  Stream.runForEach(subscription, (event) => handle(event)).pipe(
    Effect.forkScoped,
  );
```

Use `Effect.forkIn(scope)` when you have explicit scope control (e.g., `Scope.fork`, service-level scope). Use `Effect.forkScoped` as a shorthand when the fiber should be scoped to the current `Effect.gen` scope.

### Scope.fork for Sub-scopes

```ts
const subScope = yield * Scope.fork(scope, "subtask-name");
yield * work.pipe(Effect.forkIn(subScope));
```

### Do Not Use

- `Effect.fork` — doesn't exist in v4
- `Effect.forkDaemon` — doesn't exist in v4
- `Effect.forkChild` / `Effect.forkDetach` — available but `forkIn` / `forkScoped` are preferred for scoped background work

## Effect.cached — Deduplication

Use `Effect.cached` when multiple concurrent callers should share one in-flight computation. It memoizes the effect — the first caller triggers execution, and subsequent callers get the same result without re-executing.

```ts
// packages/core/src/image.ts
const loadAdapter = yield * Effect.cached(loadHeavyAdapter());

// Subsequent calls reuse the cached adapter
const adapter1 = yield * loadAdapter;
const adapter2 = yield * loadAdapter; // same instance, no re-execution
```

Do **not** hand-roll `Fiber | undefined` or `Promise | undefined` for this pattern. `Effect.cached` handles concurrency, error propagation, and cleanup.

## Deferred — One-Shot Signal

`Deferred` is a one-shot promise-like primitive. One fiber completes it; other fibers await it.

```ts
// packages/core/src/session/run-coordinator.ts
const done = Deferred.makeUnsafe<A, E>();
const settled = Deferred.makeUnsafe<Exit.Exit<A, E>>();

// Producer
Deferred.doneUnsafe(entry.done, exit);

// Consumer
yield * Deferred.await(entry.settled);
```

Use `Deferred.makeUnsafe()` inside synchronous code that already runs in an Effect context (inside `Effect.gen` or `Layer.effect`). Use `Deferred.make` (capital-M) when you need the scope-safe variant.

## FiberSet — Dynamic Fiber Pool

`FiberSet` manages a dynamic set of concurrent fibers. Fibers are added with `FiberSet.run` and can be interrupted with `FiberSet.clear`. The set yields when all fibers complete (`FiberSet.join`) or when it becomes empty (`FiberSet.awaitEmpty`).

```ts
// packages/core/src/session/runner/llm.ts
const toolFibers = yield * FiberSet.make<void, ToolOutputStore.Error>();

// Run multiple tools concurrently
toolOutputs.forEach((output) =>
  storeToolOutput(output).pipe(FiberSet.run(toolFibers)),
);

// Wait for all tools to finish
yield * FiberSet.join(toolFibers);

// Or: interrupt all tools
yield * FiberSet.clear(toolFibers);
```

## FiberMap — Keyed Fiber Pool

`FiberMap` is like `FiberSet` but keyed — each key can have at most one running fiber.

```ts
// packages/opencode/src/control-plane/workspace.ts
const syncFibers = yield * FiberMap.make<WorkspaceV2.ID, void, SyncLoopError>();

yield * FiberMap.run(syncFibers, space.id, syncLoop(space));
```

## `Effect.callback` — Callback Interop

Use `Effect.callback` to bridge callback-based APIs into Effect fibers:

```ts
yield *
  Effect.callback<void, Error>((resume) => {
    const onAbort = () => resume(Effect.fail(new Error("Aborted")));
    signal.addEventListener("abort", onAbort, { once: true });
    return Effect.sync(() => signal.removeEventListener("abort", onAbort));
  });
```

The callback receives a `resume` function and may return an optional cleanup effect. Use it for native callbacks, event listeners, and any API that delivers values asynchronously through a callback.

**Opencode reference:** `packages/core/src/process.ts:L92`

## Effect.raceFirst — First to Complete

`Effect.raceFirst` runs multiple effects concurrently and returns the result of the first one to complete (success or failure). The others are interrupted.

```ts
yield *
  Effect.raceFirst(
    Deferred.await(entry.settled),
    Deferred.await(shutdown).pipe(Effect.as(Exit.void)),
  );
```

## Effect.all — Fan-Out

Run effects concurrently with configurable concurrency:

```ts
// Unbounded parallelism
const [a, b, c] =
  yield * Effect.all([taskA, taskB, taskC], { concurrency: "unbounded" });

// Sequential (default)
const [a, b] = yield * Effect.all([taskA, taskB]);

// Bounded parallelism
const results = yield * Effect.all(tasks, { concurrency: 4 });
```

## Fiber.interrupt — Cancellation

```ts
// packages/core/src/session/run-coordinator.ts
return Fiber.interrupt(entry.owner);
```

## Effect.repeat / Effect.schedule — Background Loops

For persistent background loops, use `Effect.repeat` or `Effect.schedule` with `Effect.forkScoped`:

```ts
yield *
  pollLoop.pipe(
    Effect.repeat(Schedule.spaced("10 seconds")),
    Effect.forkScoped,
  );
```

## Effect.timeoutOption — Optional Timeout

```ts
const result =
  yield * Deferred.await(job.done).pipe(Effect.timeoutOption(input.timeout));
// Returns Option<A> — None if timed out, Some(value) otherwise
```

## Semaphore — Mutual Exclusion

For local mutex patterns:

```ts
const lock = Semaphore.makeUnsafe(1); // inside Effect.gen
// or
const lock = yield * Semaphore.make(1); // scoped

yield *
  lock.take(1).pipe(
    Effect.tap(() => criticalSection),
    Effect.ensuring(lock.release(1)),
  );
```

## RcMap + TxReentrantLock — Read/Write Locking

Used in the storage service for file-level read/write locking:

```ts
// packages/opencode/src/storage/storage.ts
const locks =
  yield *
  RcMap.make({
    lookup: () => TxReentrantLock.make(),
    idleTimeToLive: 0,
  });

yield * TxReentrantLock.withWriteLock(rw, writeOp);
yield * TxReentrantLock.withReadLock(rw, readOp);
```
