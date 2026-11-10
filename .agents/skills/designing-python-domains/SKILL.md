---
name: designing-python-domains
description: "Structures Python business logic as methods on parsed Pydantic v2 models. Use when creating or refactoring Pydantic models, domain objects, service operations, or handlers around them."
---

# Designing Python Domains

Shape Python APIs around domain concepts: parse untrusted input once at the owning boundary into Pydantic v2 models, then express business rules as methods and properties on those models. Callers stay thin: parse, call 1–2 model methods, return.

Framework callbacks, validators, serializers, dependency providers, and infrastructure adapters are exempt where noted below.

## Start With Local Conventions

Read the nearest project guidance and neighboring modules before choosing a shape. Preserve an established local convention unless it creates a concrete correctness or maintenance problem.

Do not refactor only to replace `process_order()` with `Order.process()`. The new shape must improve ownership, discoverability, or lifecycle management.

## Module Anatomy

One domain concept per module, one primary public model. Co-locate supporting variants, constrained aliases, and errors when they belong to that concept. Declare the public API in `__all__` (`__all__` documents intent; it does not block explicit imports).

```python
from typing import Self
from pydantic import BaseModel, ConfigDict

__all__ = ["Order"]

class Order(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)

    total: float

    @classmethod
    def from_raw(cls, raw: object) -> Self:
        # ONLY place that touches untyped wire shapes.
        return cls.model_validate(raw)

    @property
    def is_free(self) -> bool:
        return self.total == 0

    def effective_total(self, *, discount: float = 0.0) -> float:
        return max(self.total - discount, 0.0)
```

Consumers do `from shop.orders import Order`, then `Order.from_raw(raw)` and `order.is_free`. No `import *`, no `as` aliases.

Do not invent a shared `DomainModel` base class solely to deduplicate three config settings.

## Parse at the Boundary

Parse external representations at their owning boundary; pass trusted values inward. Each boundary parses its own input (HTTP request, downloaded metadata, inference result) — this is per-boundary parsing, not a single global parse.

| Input | Path |
|---|---|
| Python value into a concrete model | `Order.model_validate(raw)` |
| JSON bytes/text into a concrete model | `Order.model_validate_json(raw)` |
| Collection, union, or constrained scalar | Reusable `TypeAdapter(T)` |
| Source-specific adaptation | `from_*` constructor that owns the adaptation |

Rules:

- `from_*` only when it owns meaningful source-specific adaptation, not as a mandatory alias for `model_validate`. Never dump and reparse an already-parsed model to follow the shape.
- Prefer `raw: object` at unknown-input boundaries. Unlike `Any`, it forces narrowing before indexing or calling methods. Confine unavoidable `Any` to a narrow untyped adapter; never domain fields or public results. `object` is a safe top type, not an escape hatch.
- Validators must be synchronous, deterministic, and side-effect-free; correctness must not depend on invocation count. Pydantic may skip or re-run validators (nested revalidation, unvalidated defaults).
- No I/O, billing, logging-dependent behavior, or resource resolution inside validators. Use `validate_default=True` where a constrained default must validate.
- Checks depending on current external state belong in an operation, not in a parser.
- `Annotated` constraints run when Pydantic parses values; they are not nominal brands. Annotating a method return with a constrained alias does not validate the returned value.

## Aliases, Immutability, Updates

- Prefer `validate_by_name` / `validate_by_alias` over new uses of `populate_by_name`.
- `validation_alias` and `serialization_alias` are different contracts. A validation alias does not change `model_dump()` output; add a serialization alias when the output contract needs it.
- Use `AliasChoices` only for representations genuinely supported now, not speculative compatibility. It defines priority order, not agreement between supplied values — specify the duplicate-name policy when several aliases are accepted.
- `frozen=True`: default for parsed snapshots and value objects, not every stateful object. Frozen is shallow — a `list` or `dict` field still mutates through itself. Use immutable collections and immutable nested models when the invariant must persist.
- `extra="forbid"`: default for new closed contracts you own. For external payload projections, explicitly choose whether unknown fields are accepted.
- `strict`: contract-specific, not universal. Prefer explicit strict fields where coercion is invalid. Strict JSON and strict Python accept different representations; never narrow endpoint acceptance just to satisfy a default.
- `model_construct()` and `model_copy(update=...)` are not validated construction or update paths. Reconstruct through validation when values change.

## Operations, Errors, Async, Resources

Separate three kinds of code: pure domain operations (directly importable), runtime capabilities (injected IO, resources, config, swappable implementations), and scoped request data (passed explicitly from transport context into the operation).

- Property only for a cheap, deterministic, argument-free observation of an already-valid model. Method for expensive computation, parameters, mutation, effects, or async work.
- No network access, hidden dependency lookup, or heavy loading in properties. Use `@computed_field` only when the derived value intentionally belongs in the output contract.
- Effectful work takes dependencies explicitly (`order.load(session)`). Positional `bool` flags are banned; use keyword-only options (`def with_opts(self, *, deduplicate: bool = False)`).
- Keep clients, locks, tensors, and sessions out of Pydantic fields. Do not add `arbitrary_types_allowed=True` to turn models into service containers.
- Resolve expensive resources once in lifespan or composition and pass references in. Per-request injection (FastAPI `Depends` default cache) is transport wiring, not an application singleton. Domain imports must not load heavy resources.
- Introduce a small `Protocol` only when it creates a useful external boundary, not for every collaborator.
- Parsing stays synchronous. `async def` does not offload blocking work; keep blocking calls out of async callers or move them to a real threadpool.

Errors (no checked error channel in Python — use ordinary, specific exceptions):

- Validators report bad input with `ValueError` or `PydanticCustomError`; `TypeError` escapes rather than becoming a validation error.
- Catch infrastructure exceptions only to recover or translate them into a meaningful domain or operation failure, preserving cause with `raise ... from exc`.
- Map domain failures to transport responses in the transport layer. Distinguish invalid client input from invalid upstream output; they are not both client errors.
- Do not catch `Exception` merely to turn programming failures into a 400.

## Helpers: Methods Over Free Functions

- Forbidden outside models: `process_*`, `transform_*`, `handle_*`, `compute_*` business functions and `*_utils.py` dumping grounds. A free function that only reads one model belongs on that model.
- Forwarding wrappers that rename an obvious operation are banned. A named domain predicate or property is allowed when it owns a business rule, even if implemented in one expression.
- A private `_helper` lives in the same file below the model and only on third use. Exempt from the third-use rule: validators, serializers, dependency providers, context managers, framework callbacks, and public operations owning a real rule. Definition order matters: decorator and `Annotated[..., AfterValidator(cb)]` callbacks must exist before use.
- Ban caller-side rediscovery of wire shapes, not all `isinstance`. Tagged-union narrowing and infrastructure adaptation stay valid. Representation decisions (e.g. `str | list[str]` normalization) belong at the input boundary or model, not scattered across callers.

## Enforcement

| Tool | Useful checks | Do not claim |
|---|---|---|
| Ruff | `FBT001/002` positional bool params, `FBT003` boolean calls, `ANN401` whole-annotation `Any`, `BLE001` broad catch, import/annotation rules | Business ownership, all `Any` leakage, third-use counting |
| Typechecker | Argument/return compatibility, narrowing, invalid operations | Runtime constraints, deep immutability, parse-once proof |
| ast-grep | Scoped rules: framework imports inside domain dirs, async validators, `model_construct` / `model_copy(update=)` | Semantic purity, whether a one-liner owns a rule |

Treat construction-bypass and scope violations as review warnings in shared code, not global hard-fails. Never hard-fail on every free function, `isinstance`, property length, or model count — those reject legitimate framework and parsing code. Document actual Python checks per project; do not copy another language's enforcement claim unchanged.

## Refactoring Workflow

1. List the current operations and the data or dependencies each one uses.
2. Separate pure transformations from IO, mutable state, and scoped runtime data.
3. Name the domain concept callers should see.
4. Move each rule about a domain value onto that value (`from_*`, validator, property, method).
5. Keep one canonical construction path per representation.
6. Update call sites to read as domain vocabulary: parse, call model methods, return.
7. Verify dependencies remain explicit and test the public behavior.

## Review Checklist

- Does the API name a domain concept rather than an implementation category?
- Is untrusted input parsed at its owning boundary and trusted inward?
- Does every business rule about a value live on that value?
- Are validators sync, deterministic, and side-effect-free?
- Are state-dependent checks operations, not parsers?
- Is every property cheap, argument-free, and effect-free?
- Do effectful methods take explicit dependencies and keyword-only options?
- Are models free of clients, sessions, and heavy import-time loading?
- Is there exactly one obvious construction path per representation?
- Are private details unexported or declared non-public via `__all__`?
- Did the change reduce coupling as well as visual function noise?

## Testing

Test repository-owned rules through public model behavior, not validation mechanics or dependency-injection caching. Cover each distinct failure mode at the cheapest useful level; a docs-only skill change needs no application tests.

## References

- [Pydantic v2 models](https://docs.pydantic.dev/latest/concepts/models/)
- [Pydantic fields and aliases](https://docs.pydantic.dev/latest/concepts/alias/)
- [Pydantic strict mode](https://docs.pydantic.dev/latest/concepts/strict_mode/)
- [Pydantic validators](https://docs.pydantic.dev/latest/concepts/validators/)
- [Pydantic TypeAdapter](https://docs.pydantic.dev/latest/concepts/type_adapter/)
