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

## Review decisions

The code-quality phase and review read a Rails change for these four decisions. Check the locked Rails version, the database adapter and the queue backend where they bear on a finding.

- **Associations and data modeling.** Match cardinality and foreign-key placement to the domain. Compare declarations with the actual schema: composite uniqueness, tenant scope, nullability and deletion behavior. Follow alternate writers and bulk operations. Walk through two concurrent requests when uniqueness, inventory or a state transition matters. Check whether historical facts survive later edits to related records.
- **Object design.** Trace which object owns each decision and which callers must agree. Look for duplicated rules, missed entry points, hidden callback effects, and an external dependency that complicates testing. Prefer the smallest cohesive change a concrete use case supports. Class size, or the absence of a service object, does not establish a defect.
- **Performance.** Follow the query from its construction through iteration, rendering or serialization. Check preloads, aggregates, indexes, batch bounds, row multiplication and memory use. Say how work grows with input size. Use a local query count, a representative fixture or a query plan when one is available, and label estimated impact separately from measurements.
- **Reliability.** Trace transaction boundaries, locks, external calls, enqueue timing and retries. Walk through a failure just after an external side effect and before local acknowledgment. Inspect idempotency keys, provider guarantees and reconciliation before recommending retries. For a backlog or a crashing process, look at the evidence on arrival rate, throughput, connections, memory and downstream capacity before changing concurrency.

When a schema change is needed, account for existing rows, concurrent writes, mixed application versions during deployment, and the adapter's locking behavior.
