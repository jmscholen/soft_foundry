# Deviations From Plan

Two additions the recommended shape did not contain, both forced by this change's own process and recorded here so the reader knows they were not planned:

1. **Staleness measured on the record's own branch** (REQ-RUN-008). Plan: none. Why: `ci` on this branch, stacked on `change/runtime-guard`, reported the runtime-guard record's commit-bound evidence as stale against this branch's code, which that evidence never claimed to cover. Requirements affected: the gate semantics in `.ai/schemas.md`; no requirement of the runtime-guard change. Approval: the maintainer's, at merge; the alternative (rebinding the earlier record here) was rejected as dishonest.
2. **Hooks prefer a checkout's own executable** (REQ-RUN-009). Plan: none. Why: the pre-commit hook in this repository ran an installed 0.3.0 gem and rejected two commits the checkout's `ci` passes; evidence generated between those attempts was discarded and regenerated at the real commit. Requirements affected: none of an earlier change; the hook text in `hooks.rb`. Approval: the maintainer's, at merge.

Each deviation records: what changed, why the plan could not be followed, which requirements are affected, and who must approve it.
