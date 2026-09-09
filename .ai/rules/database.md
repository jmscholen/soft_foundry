# Database Standard

- Treat the database as an integrity boundary, not only a persistence mechanism.
- Use constraints, indexes, foreign keys, and uniqueness guarantees for important invariants where supported.
- Evaluate query plans and index impact for material access patterns.
- Avoid unbounded queries and memory-loading patterns on potentially large datasets.
- Migrations must be designed for the target production data volume and deployment topology.
- Backfills should be restartable, observable, and separated from locking schema changes when appropriate.
- Explicitly reason about transactions, isolation, race conditions, and duplicate execution for concurrent workflows.
- Do not perform destructive data changes without approved safeguards and recovery strategy.
