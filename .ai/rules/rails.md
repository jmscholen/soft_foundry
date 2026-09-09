# Rails Standard

- Controllers coordinate HTTP concerns; do not accumulate domain workflows in controllers.
- Models may own persistence-aware domain behavior but must not become indiscriminate dumping grounds.
- Authorization must be explicit at relevant entry points and scoped to the actual resource being acted upon.
- Strong parameters are not a substitute for authorization or domain validation.
- Background jobs must be safe under retry semantics; prefer idempotent handlers where duplicate execution is possible.
- External network calls require explicit timeout and failure behavior.
- Avoid holding database transactions open across avoidable network calls.
- Back important invariants with database constraints when feasible.
- Schema changes must consider production size, locking, backfills, deployment ordering, rollback, and mixed-version application operation.
- Detect and prevent N+1 query behavior on material request paths.
- Avoid callbacks for multi-step business workflows when an explicit service/workflow object would make control flow clearer.
- Treat user-controlled values, uploaded files, identifiers, redirect targets, and serialized input as untrusted.
