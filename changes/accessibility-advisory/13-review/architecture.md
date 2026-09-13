# Architecture Review

## Scope reviewed
Placement of the advisory logic relative to `Gate`, `ChangeRecord`, `ControlPlane`, and the CLI; the new `ControlPlane#repository_profile`; the `Advisory::UI_FRAMEWORKS` constant shared by `change new`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-004 | info | `lib/soft_foundry/advisory.rb` | Advisories are a separate read-only class over a record, not extra `Gate` checks. Correct separation: gate answers "is this phase's evidence complete", advisory answers "what should a human know before shipping", and the exit-code contract of `Gate::Result#failed?` is untouched. | `.ai/rules/architecture.md` (cohesive responsibilities) |
| REV-005 | info | `lib/soft_foundry/change_record.rb` `declare_accessibility_surface!` | A text edit on a file the same method just wrote, guarded by a regex on the `accessibility:` line and a no-op when nothing matches. Acceptable and explained (comments must survive); a future template restructure must keep that line's shape or the flag silently stays false, which the advisory would then report in a UI repository. | `.ai/rules/general.md` (side effects explicit) |
| REV-006 | info | `Advisory::UI_FRAMEWORKS` vs `MaturityScan#detected_frameworks` | Two lists of the same names in two files. Recorded in decisions.md; a scan extension must extend both. Not worth a shared constant today because the scan's names are derived from detection logic, not a list. | `.ai/rules/general.md` |

## Conformance
Conforms.
