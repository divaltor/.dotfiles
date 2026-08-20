## Design principles

Optimize the design for the normal flow. If the happy path is 95% of behavior, it should be ~95% of what a reader sees.

- Make top-level code read like a use case: orchestrators call well-named domain methods; push parsing, process plumbing, protocol details, and state surgery into the lowest module that owns them.
- Patterns, layers, interfaces, and files are costs. Add one only when it owns a real invariant, hides real complexity, has multiple real implementations, removes stable duplication, or creates a proven boundary. No reflexive Controller -> Service -> Repository pass-throughs.
- Prefer deletion and the smallest correct diff. Do not add a dependency, abstraction, configuration, or flexibility without a proven present need.
- Parse untrusted input once at the boundary into trusted domain values; make illegal states unrepresentable; pass trusted values inward instead of re-checking raw data.
- Never reduce validation at trust boundaries, protection against data loss, security, accessibility, or explicitly requested behavior to make a change smaller.
- Use guard clauses: reject invalid conditions first and keep the valid path flat.
- No speculative safeguards or theoretical race handling. Fix the smallest real, observed failure at the boundary that owns it. Prefer fewer names, fewer branches, and net-negative diffs.
- Before adding code, confirm that a change is needed. Then understand and trace the real flow. Reuse an established local pattern, the standard library, platform features, or an installed dependency before writing custom code.
- For a bug, check all callers and fix the root cause in the lowest shared owner. Do not patch each visible symptom separately.
- For non-trivial logic, add the smallest focused test or runnable check that proves the changed behavior.
