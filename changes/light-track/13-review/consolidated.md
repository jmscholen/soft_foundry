# Consolidated Review

Commit reviewed: 2bd8a36ebac217d90174639deddb292765665b07. No blocking finding. Two major findings, eleven minor.

## Functional
The three must criteria are met: a light record gates, seals and closes without its optional phases while the gated twin fails (AC-001); every lock fails a light record with the same check as a gated one and high risk is refused (AC-002); six spellings of a modified path are caught (AC-003). Two major findings on should-tier work: the round count still counts a second unsealed remediation (REV-001), and the text-only verify size is not reached where any git-ignored file exists (REV-002). The help text is incomplete (REV-004). README.md and the user guide, which verification and evaluation could not read, do meet AC-007.

## Architecture
The track is configuration over an existing rule, which is the simplest design that meets the requirement. Decisions are recorded. Minor: two copies of the skip-reason logic (REV-013); `check` does not refuse a track that makes review or specification optional (REV-010, outside this change).

## Security
No lock depends on the track. The removal of threat modeling, evaluation and attack for changes that opt in was approved by the maintainer and is recorded. The round count errs toward more rounds, not fewer. No evidence in this record was altered. Minor: "attack recorded as not run" is promised in three documents and instructed nowhere (REV-005).

## Accessibility
Conforms with advisories. Status output carries every reason in words and survives colour and symbol removal. The new guide has ordered headings and proper tables. Minor: a split list in README.md (REV-009); a sizing reason that does not name the cause (part of REV-002).

## Policy conformance
N/A. `surfaces.policy` is false and the diff changes nothing the tool collects, shares, retains, protects or promises. No policy text change is owed.

## Infrastructure
N/A. Nothing under `infra/`, CI, or the gem's dependencies changed.

## Operations
`change status` shows the track and why each phase did not run. Minor: a judged light record reads `phase: learn` (REV-007); the version is unchanged while behavior differs from the installed gem (REV-012); the guard hook misreports when run from inside the record (REV-011, outside this change).

## Blocking findings
None.

## Residual concerns
| ID | Severity | Summary |
| --- | --- | --- |
| REV-001 | major | A second remediation that was completed but never sealed is counted as a round; the change parks one round early. |
| REV-002 | major | The text-only verify size is not reached in a repository holding a git-ignored file, which is every repository where the tool has run. AC-005 (should) is unmet in practice. |
| REV-003 | minor | A file with a glob character in its name (`app/[id]/page.tsx`) cannot be named in an outside-change finding. Specified behavior; a point for the next specification. |
| REV-004 | minor | `soft-foundry help` names the light track only as a `--track` value. AC-007 (should) is met in part. |
| REV-005 | minor | Nothing tells judgment to record attack as not run on a light record. |
| REV-006 | minor | `sealed` in a reopen entry is not in `.ai/schemas.md`. |
| REV-007 | minor | `current_phase` is `learn` after judgment on a light record. |
| REV-008 | minor | Letter case and backslash spellings pass the outside-change check. |
| REV-009 | minor | README.md track list is split in two. |
| REV-010 | minor, outside this change | `check` does not refuse a track whose optional list names review, specify, implement or verify. |
| REV-011 | minor, outside this change | The guard's after-call hook writes stray directories and reports a restore when run from inside the record. |
| REV-012 | minor | Version not raised; the installed gem and the source both report 0.23.0. |
| REV-013 | minor | Two skip-reason functions with different vocabularies. |

For judgment: this record ran no attack phase (stepped over by default at low risk), so its own judgment should record attack as not run. AC-009 is met except the one track-list assertion (DEV-003). PC-001 is still owed by the maintainer after merge.
