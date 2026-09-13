# Operations Review

## Scope reviewed
What an operator sees and does differently after this change: the `advisory:` block on `gate`, `change status`, `ci`, and `change close`; the `check` warning; the level-5 maturity requirement; the auto-set flag on `change new`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-016 | info | `README.md`, `.ai/schemas.md`, `AGENTS.md` | The advisory semantics (informational, never an exit-code change, what each area means, where it prints) are documented in all three places an operator or agent reads. | `.ai/rules/general.md` (new behavior must be detectable and explained) |
| REV-017 | info | `.ai/maturity.yml` level 5 | Adding a required capability can lower an already-assessed repository's reported level on its next reassessment until `.ai/rules/accessibility.md` is installed; installing the standard is the whole remedy and `check` names it. This repository's own profile already records PASS. | `.ai/maturity.yml` assessment rules |
| REV-018 | info | this change record | Running `gate all --change accessibility-advisory` prints its own advisory block (specification skipped, judgment skipped). That is the feature working on itself, and the maintainer should read those two lines before merging. | REQ-A11Y-004, REQ-A11Y-005 |

## Conformance
Conforms.
