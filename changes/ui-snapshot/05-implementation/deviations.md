# Deviations From Plan

Three test expectations committed at RED were wrong about existing behaviour, not about the feature, and were corrected in the GREEN commit. No requirement changed and no approval beyond the maintainer's review of this record is needed.

1. Staleness after a merge. The RED test changed code on `main` and expected the record to go stale. The gate measures staleness on the record's own branch when another branch is checked out (`Gate#staleness_check`), so the test now changes code on the record's branch. Affects the test for REQ-SNAP-003 only.
2. Non-UTF-8 text. The RED test wrote an invalid byte into `metadata.yml` and expected a readable title. YAML refuses such a file outright, so that record is an unreadable row (already tested). The test now exercises `Snapshot.plain` directly on a binary string, a Symbol, a Time, a Date, and a NaN. Affects the test for REQ-SNAP-006 only.
3. Budget cap. The RED test hard-coded the default cap; a low-risk change has its own cap in `.ai/policies/budget.yml`. The test now compares against `Budget.policy`. Affects the test for REQ-SNAP-005 only.

Each deviation records: what changed, why the plan could not be followed, which requirements are affected, and who must approve it.
