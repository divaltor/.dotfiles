# Testing Effect Services

This document covers the test patterns used in the opencode repo. Most tests run inside a per-file `testEffect` runner that wires the right test environment (clock, console, temp instance) for the assertion being made.

## The `testEffect` Runner

Every Effect test file starts with a single local runner. Pick the variant that matches the test's behavior — clock-controlled, real time, or real time plus a scoped opencode instance.

```ts
import { describe, expect } from "bun:test"
import { Effect, Layer } from "effect"
import { testEffect } from "../lib/effect"

const it = testEffect(Layer.mergeAll(MyService.defaultLayer))

describe("my service", () => {
  it.effect("pure service behavior", () =>
    Effect.gen(function* () {
      const svc = yield* MyService.Service
      expect(yield* svc.run()).toEqual("ok")
    }),
  )
})
```

### Runner Variants

| Method | Clock | When to use |
| --- | --- | --- |
| `it.effect(name, body)` | `TestClock` | Pure Effect behavior that should be hermetic — no real time, no real FS |
| `it.live(name, body)` | Real | Behavior that depends on real time, FS mtimes, child processes, git, locks, watchers, OS |
| `it.instance(name, body, options?)` | Real | Live Effect test that needs one scoped opencode instance (temp dir + `InstanceRef`) |

Each variant has matching `.only` and `.skip` modifiers, and the same body type: an `Effect` or a thunk returning an `Effect`. Use a thunk when the body needs to close over per-test data built from the runner.

### `it.instance` Options

```ts
it.instance(
  "plugin-registered agents appear in Agent.list",
  () =>
    Effect.gen(function* () {
      yield* Plugin.Service.use((p) => p.init())
      const agents = yield* Agent.use.list()
      // ...
    }),
  { config: { plugin: [pluginUrl] } },
)
```

- `git?: boolean` — initialize a git repo with a root commit
- `config?: Partial<Config.Info> | (() => Partial<Config.Info>)` — write `opencode.json`
- `init?: (dir: string) => Effect.Effect<void, E, R>` — custom setup Effect that runs after the dir is bound

`it.instance` is the default for any test that touches `InstanceRef`, `InstanceState`, or any per-directory state. It skips `InstanceBootstrap` so LSP/MCP don't spin up and hang on Windows during scope teardown.

### `testEffectShared` (rare)

```ts
testEffectShared(layer)
```

Builds the test layer through the process-wide `memoMap` so cached services (`Bus`, `Session`, …) match the `Server.Default` instances. Use only when a test publishes to an in-process HTTP server and needs pub/sub identity with the server's handlers. Most tests stick with `testEffect`.

## Style

- Define `const it = testEffect(...)` near the top of the file.
- Keep the test body inside `Effect.gen(function* () { ... })`.
- Yield services directly: `yield* MyService.Service` or `yield* MyTool`.
- Avoid custom `ManagedRuntime`, `attach(...)`, or ad hoc `run(...)` wrappers when `testEffect(...)` already provides the runtime.
- When a test needs instance-local state, prefer `it.instance(...)` over manual `Instance.provide(...)` inside Promise-style tests.

## Fixtures

Prefer the Effect-aware helpers from `test/fixture/fixture.ts` over hand-rolled tempdir logic in each test.

| Helper | Purpose |
| --- | --- |
| `tmpdirScoped(options?)` | Creates a scoped temp directory, cleaned up when the Effect scope closes. Returns the path string. |
| `provideInstance(dir)(effect)` | Low-level: runs an effect with `InstanceRef` provided for `dir` without creating a directory. |
| `provideTmpdirInstance((dir) => effect, options?)` | Creates a temp dir, binds it as the active instance, and disposes the instance on cleanup. |
| `provideTmpdirServer((input) => effect, options?)` | Same as above, plus provides the test LLM server. |
| `TestInstance` (Context.Service) | Yields `{ directory: string }` for the current instance. |
| `disposeAllInstances()` / `disposeAllInstancesEffect` | Tear down every cached instance. Use in `afterEach` for integration tests that intentionally touch the shared registry. |
| `reloadInstance(input)` / `reloadInstanceEffect(input)` | Invalidate and re-load a specific instance. |

### `TestInstance`

Yield `TestInstance` from inside `it.instance(...)` when the test needs the temp directory path:

```ts
import { TestInstance } from "../fixture/fixture"

it.instance("uses the temp directory", () =>
  Effect.gen(function* () {
    const test = yield* TestInstance
    expect(test.directory).toContain("opencode-test-")
  }),
)
```

### `tmpdirScoped`

The Effect counterpart of the Promise `tmpdir()`. Use it inside `Effect.gen` whenever the temp directory lives inside the Effect test:

```ts
it.live("InstanceState caches values per directory", () =>
  Effect.gen(function* () {
    const dir = yield* tmpdirScoped()
    let n = 0
    const state = yield* InstanceState.make(() => Effect.sync(() => ({ n: ++n })))
    // ...
  }),
)
```

The Promise-style `await using tmp = await tmpdir(...)` is the legacy form. New tests use `yield* tmpdirScoped(...)`.

### When to Reach for the Lower-Level Helpers

`it.instance(...)` covers the common case of "one temp dir, one instance context." Reach for the explicit helpers when a test needs:

- multiple directories
- custom setup before binding
- switching instance context within one test
- explicit disposal/reload lifetime assertions

## Partial Service Stubs With `Layer.mock`

When a test only needs to override one or two methods of a service, prefer `Layer.mock` over a hand-rolled `Layer.succeed(Service, Service.of({ ... }))`. `Layer.mock` lets you supply just the methods that matter — anything else throws an `UnimplementedError` defect if the test accidentally calls it, which is the signal you want.

```ts
import { Effect, Layer } from "effect"
import { Account } from "@/account/account"

const failingAccountLayer = Layer.mock(Account.Service, {
  orgsByAccount: () =>
    Effect.fail(new Account.AccountServiceError({ message: "simulated upstream failure" })),
})
```

### Boundary Fakes

Keep small reusable fake layers in `test/fake/*` for services that show up across many tests:

```ts
// test/fake/auth.ts
import { Effect, Layer } from "effect"
import { Auth } from "../../src/auth"

export const empty = Layer.mock(Auth.Service)({
  all: () => Effect.succeed({}),
})

export * as AuthTest from "./auth"
```

Then compose them at the layer boundary:

```ts
const configLayer = Config.layer.pipe(
  Layer.provide(FSUtil.defaultLayer),
  Layer.provide(Env.defaultLayer),
  Layer.provide(AuthTest.empty),
  Layer.provide(AccountTest.empty),
  Layer.provide(NpmTest.noop),
  Layer.provide(FetchHttpClient.layer),
)
```

The repo currently ships these boundary fakes:

- `AccountTest.empty` — `active`, `activeOrg` → `Option.none`
- `AuthTest.empty` — `all` → `{}`
- `NpmTest.noop` — `install` → `Effect.void`
- `SkillTest.empty` — `dirs` → `[]`
- `ProviderTest.fake()` — fully-wired `Provider.Service` with one test model; supports per-method overrides

Extract new fakes from a test only after the same boundary stub repeats across multiple files. Do not invent generic test-layer builders before that need shows up.

## Synchronization With Concurrent Work

### The Anti-Pattern

`Effect.sleep(N)` and `setTimeout` as a "wait for the forked fiber to be ready" hack race the scheduler. The forked fiber may not have reached the synchronization point within `N` ms on a slow CI host, and the test fails intermittently.

```ts
// ❌ Race
yield* prompt.shell({ command: "sleep 30" }).pipe(Effect.forkChild)
yield* Effect.sleep(50)
yield* prompt.cancel(chat.id)
```

### The Fix

Wait on a **published readiness signal**, not wall-clock time. The test helpers and service APIs below cover every common case.

| Helper | When to use |
| --- | --- |
| `pollWithTimeout(effect, message, duration?)` | Run a predicate effect repeatedly until it returns a non-`undefined` value, with a timeout (default 5s). |
| `awaitWithTimeout(effect, message, duration?)` | `Effect.timeoutOrElse` wrapper with a custom error message (default 2s). |
| `llm.wait(n)` | Wait until the mock LLM has received `n` HTTP calls. |
| `SessionStatus.Service.get(sessionID)` | Observable per-session state (`{ type: "busy" | "idle" | ... }`). |
| `BackgroundJob.wait({ id, timeout })` | Wait for a named background job to complete. |
| `Deferred.await(deferred).pipe(Effect.timeoutOrElse(...))` | One-shot signal. |
| Bus subscription + `Latch` | Fork `Stream.runForEach(bus.subscribe(Event), ...)` and open the latch in the callback to signal first-event readiness. |

```ts
// ✅ Wait for a published readiness signal
yield* prompt.shell({ command: "sleep 30" }).pipe(Effect.forkChild)
yield* pollWithTimeout(
  Effect.gen(function* () {
    const s = yield* (yield* SessionStatus.Service).get(chat.id)
    return s.type === "busy" ? (true as const) : undefined
  }),
  "session never became busy",
)
yield* prompt.cancel(chat.id)
```

### When Fixed Sleeps Are OK

- Testing debounce or throttle behavior, where the sleep **is** the test.
- Letting real wall-clock advance past a genuine timestamp resolution boundary (e.g. mtime granularity).
- Simulating network latency in race-regression tests that intentionally exercise ordering.

## Concurrency Idioms

```ts
// Fan out independent work
const [a, b] = yield* Effect.all([access(state, one), access(state, two)], {
  concurrency: "unbounded",
})

// Fork and await
const fiber = yield* runner.ensureRunning(work).pipe(Effect.forkChild)
yield* waitForState(runner, "Running")
const exit = yield* Fiber.await(fiber)

// Fork with scope cleanup
const fiber = yield* someWork.pipe(Effect.forkScoped)

// Bridge a Node/Bun Promise into the effect world
const result = yield* Effect.promise(() => fetch(url))
```

## Failure Assertions

```ts
// Flip success/failure so the error becomes the success value
const error = yield* Effect.flip(Account.use.login(url).pipe(Effect.provide(live(client))))
expect(error).toBeInstanceOf(AccountTransportError)

// Capture the Exit for richer inspection
const exit = yield* runner.ensureRunning(Effect.fail("boom")).pipe(Effect.exit)
expect(Exit.isFailure(exit)).toBe(true)
if (Exit.isFailure(exit)) expect(Cause.squash(exit.cause)).toBeInstanceOf(Runner.Busy)
```

`Cause.prettyErrors(exit.cause)` is the right tool when an assertion fails — the runner logs the pretty cause before re-raising, so a failure shows the same form the user would see at runtime.

## Anti-Patterns To Avoid

These shapes all came out of `EFFECT_TEST_MIGRATION.md` and are still being actively removed from the repo. Search for them before claiming a migration is done:

- `test(..., async () => Effect.runPromise(...))` — use `it.effect` / `it.instance` / `it.live` instead
- Local `run(...)`, `load(...)`, `svc(...)`, or `runtime.runPromise(...)` wrappers that only provide a layer
- `tmpdir()` plus legacy instance provision inside Promise test bodies
- Custom `ManagedRuntime.make(...)` in test files
- Promise `try/catch` around Effect failures
- `Promise.withResolvers`, `Bun.sleep`, or `setTimeout` for synchronization when events, `Deferred`, fibers, or deterministic state checks fit
- Mutable env/global/flag changes after layers are built

Promise helpers are acceptable at non-Effect boundaries, but yield them from inside an Effect body with `Effect.promise(...)` rather than making them the test harness.

## Conversion Recipe

When migrating a Promise test that touches Effect services:

1. Identify the real service under test and whether its open `layer` or closed `defaultLayer` is appropriate.
2. Build one top-level `layer` with real dependencies where relevant and fake layers at slow or external boundaries.
3. Replace local Promise wrappers with Effect helpers.
4. Convert `test(..., async () => { ... })` to `it.effect`, `it.instance`, or `it.live`.
5. Move `await` calls inside `Effect.gen` as `yield*` calls.
6. Replace `await using tmp = await tmpdir(...)` with `yield* tmpdirScoped(...)` when the temp directory lives inside the Effect test.
7. Replace Promise failure assertions with `Effect.exit`, `Effect.flip`, or focused assertion helpers.
8. Preserve concurrency with fibers, `Deferred`, and `Effect.all(..., { concurrency: "unbounded" })`; do not accidentally serialize formerly parallel behavior.

## Test Layout

- `test/<feature>/<feature>.test.ts` — mirrors `src/`
- `test/lib/effect.ts` — `testEffect` runner
- `test/lib/llm-server.ts` — mock LLM server
- `test/fixture/fixture.ts` — tmpdir + instance helpers
- `test/fake/*.ts` — partial service stubs
- `test/effect/*.test.ts` — tests for the effect infrastructure itself

Run from the package directory:

```sh
cd packages/opencode
bun test test/effect/instance-state.test.ts
bun typecheck
```
