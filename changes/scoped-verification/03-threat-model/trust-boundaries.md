# Trust Boundaries

Soft Foundry is a local CLI with no network listener added by this change, no accounts and no tenants. The boundaries that matter are between sessions with different write sets, between declarations and the diff they are matched against, and between recorded evidence and the facts it claims.

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| TB-1 Protected declarations vs execution sessions | `.ai/repository.yml` (`shared_core`, `access_control`), `.ai/policies/check-sizing.yml`, `.ai/workflow.yml` | Implementation, verification, evaluation and attack sessions, which cannot write `${CONTROL_PLANE}` | `permissions.yml` deny_write, runtime guard, protected-paths policy; any later edit of a declaration stales the evidence (REQ-013) |
| TB-2 Record-owned scope vs other records | A record's own `metadata.yml` `scope` | Other records under `changes/`, including closed, abandoned or malformed ones, whose scopes decide what counts as "claimed" | Scope declared in the record and reviewed; unclaimed paths stale all scoped records (REQ-003); structure check refuses blind or malformed globs (REQ-014); scope-overrun advisory (REQ-018) |
| TB-3 Git facts vs evidence claims | Commit, tree hash and diff computed by `git` | Values typed into `tests.yml` or `handoff.yml` (tree hash, outcome, cited slug, recorded size) | Tree hash recomputed from the evidence commit and compared, never trusted from the file; cited record read from `changes/`; fail closed on any git error (REQ-007, REQ-016) |
| TB-4 Tracked content vs the worktree | Tracked content identified by the tree hash | Untracked, ignored and dirty files, which the tree hash does not cover | Reuse refused while any code path is dirty (REQ-007) |
| TB-5 Declaration text vs the matcher | Glob strings from metadata and profile | Repository paths, which are attacker-influenceable names | Path-only glob matching against repository-relative git paths, no content inference, no execution, no shell interpolation (REQ-015) |
| TB-6 Structural gate vs the claim it appears to make | Gate and CLI output | A reader (person, agent, CI log) deciding whether the suite passed | Output and docs never say a passing gate proves the suite passed (REQ-008); Soft Foundry never runs the suite |
| TB-7 Sizing computation vs the evidence recorded | Policy-computed check size | Verification, evaluation and attack evidence stating a size | Gate refuses a recorded size smaller than the computed one (REQ-011); no check dropped (REQ-012) |
