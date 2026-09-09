# General Coding Standard

These rules apply to all implementation work unless a more specific repository rule is stricter.

- Prefer the simplest design that fully satisfies the approved specification.
- Preserve established repository conventions unless the specification or plan explicitly changes them.
- Keep responsibilities cohesive and public interfaces small.
- Make side effects, mutation, concurrency, retries, and failure handling explicit.
- Do not swallow errors or convert failures into apparent success.
- Do not introduce dead code, speculative abstractions, unexplained TODOs, or unused dependencies.
- Validate externally controlled input at trust boundaries.
- Preserve backwards compatibility unless the specification explicitly authorizes a breaking change.
- Make important invariants enforceable with code, schema constraints, types, policies, or deterministic checks where appropriate.
- A new production failure mode is incomplete unless there is a practical way to detect it.
- Never weaken requirements, tests, security controls, or observability merely to make an implementation pass.
- Prefer deterministic, repeatable behavior and idempotent operations where retries or repeated execution are possible.
- Changes outside the approved scope must be documented as deviations and justified before they are incorporated.
