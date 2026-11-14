# Trust Boundaries

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| Person to record | The maintainer's decisions (must-list approval, remediation cap, docs-only reopen) | Agent sessions that want the change to finish | human_decisions entries a person writes; guard refusal of Edit/Write to metadata.yml; never_autonomous policy; seal note for hand-edited keys |
| Phase-run session to tool | A session running one phase under SOFT_FOUNDRY_PHASE | Reopen, reset and decision commands | PhaseReopen refuses inside a phase-run session (existing); the docs-only option inherits it |
| Record metadata to git history | Editable metadata.yml (phase_reopenings, status, rules version) | Commits on the record's branch (Record <slug> <phase>) | Round count and rules version read from commits, not only from editable fields |
| Diff to sizing and docs-only | Paths computed from git | A session's description of its own change | Documentation-only decided from the diff; .ai/ excluded |
| Specification lock | 02-specification at its sealing commit | Later edits by any phase | Existing specification-lock check plus the approval comparison |
