# Specification Readiness

## Blocking unknowns
None. Every unknown from discovery is resolved by a decision in `specification.md`:

| Unknown | Decision |
| --- | --- |
| Canonical versus user-edited detection | SHA-256 manifest at `.ai/manifest.yml` (REQ-004, REQ-006) |
| Installing `harness-evals/` and `repository.yml` | Template only, README only (REQ-003) |
| Conflict option | `--force`, default report-only (REQ-006) |
| When to scaffold `docs/user/` | Only when `docs/` absent or `docs/user/` present (REQ-008) |
| Minimum Ruby | 3.2 (REQ-015) |
| Dirty worktree | Not refused; every file is reported (REQ-005) |
| Worktree and submodule roots | `git rev-parse --show-toplevel` (REQ-001); planning adds a worktree test |

## Untestable criteria
None. AC-013 requires a test double for the packaged source directory; AC-014 requires a symlink fixture. Both are feasible with the existing `with_fixture_repo` helper.

## Ready for threat modeling and planning
Yes. The change is medium risk because it writes into user-owned repositories; the conflict, manifest, and root-confinement requirements are the controls the threat model should attack first.
