# Operations Review

## Scope reviewed
What a person operating the tool sees and runs. That covers `change status` (checked live on this record), the `phase run quality` help text, `soft-foundry ci` on existing records (verification CHECK-004 passed), and the upgrade path for repositories already initialized. `.ai/repository.yml` is "state" to the installer and is never overwritten on update. A repository without `quality_gate` reads as off until `onboard --reassess`, which then sets it from languages (the `nil` key path, tested). Also: the full-suite runtime (VER-003) and the installed-binary skew (VER-002).

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-007 | minor | `.ai/harness-evals/` (not read) | No harness eval case covers the new `quality findings classed` check (DEV-003). The implementation skill could not write one. | A later regression in the check is caught only by the unit tests, not by `soft-foundry eval`. | Follow-up |
| REV-008 | minor | local install | The globally installed `soft-foundry` predates this branch and reports `06a-code-quality missing FAIL` for this record (VER-002). Gate and seal this record with the worktree's `lib/`, or install the branch locally first. | A seal run with the old binary refuses this record for a reason that is not real. | Operations |

## Conformance
Conforms with minor findings. PC-001 (the maintainer's post-merge check) will not see the phase *required* in a freshly initialized repository until REV-001 is fixed. The phase is still listed, with the reason "the quality gate is off".
