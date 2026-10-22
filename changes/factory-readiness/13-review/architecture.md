# Architecture Review

Commit reviewed: a9fac32d0c0e2d8951ee09ed0a5c9a8102c34637.

## Scope reviewed
Placement and coupling of the new pieces: `Guard` (preventive check, `OWN_FILES` baseline/restore, panel narrowing), `HarnessEval`, `Hooks` (PostToolUse entry, `clearing_baseline`), `Gate` (`waivers_check`, `specification_lock_check`, `staleness_check`), `SoftFoundry.read_text`, plus `05-implementation/decisions.md`, `deviations.md` and `09-remediation/summary.md`.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | `README.md` guard section; `.ai/policies/enforcement.yml` lines 22-27; this repository's `.claude/settings.json` | The documentation REM-001 to REM-006 each recorded as owed is still not written. `enforcement.yml` still says Bash "refuses commands that name a denied path and passes everything else"; README has no mention of the post-call check, `guard --after`, the Grep/Glob matcher, or that an existing repository must rerun `hooks install --claude`. This repository's own `.claude/settings.json` carries neither the PostToolUse entry nor the Grep/Glob matcher (a search of `.claude` for both finds nothing). | MIT-001 now rests on the post-call restore. A maintainer upgrading an existing repository does not know to rerun `hooks install`, so the restore and the search-tool guard never run there, and the stated "block" is only the spelling-sensitive preventive check. In this repository the restore is inactive until the maintainer reruns it. | REQ-FR-004, REQ-FR-010, AC-FR-021 |
| REV-005 | minor | `lib/soft_foundry/guard.rb` in this repository | The guard's code is in the implementer's write set when the product is the guard (ATK-F12). A weakened `decide` would be allowed and, per attack B6, silent. | A steered implementation session edits the guard to allow a policy write; only review and attack catch it. Dogfooding only: in an application repository the guard is in the installed gem outside every path group. | Anti-fudging policy; decision recorded in REM-005 |

Structure is sound: the preventive check and the detective restore are separate methods; the restore never writes through a link; `Decision` rescue fails closed; the baseline is recorded only by a shell call and cleared by `hooks install/uninstall`; gate checks compose through `recorded_commit` rather than parallel state. The accepted-residual list in REM-002 to REM-005 is honest and consistent with the attack record. The control-plane and documentation writes outside the implementation write set are declared in `deviations.md` item 1 and accepted by the maintainer at merge.

## Conformance
Conforms with advisories. REV-001 is the one item that makes the stated control weaker than the record says, until applied.
