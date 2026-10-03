# Operations Review

## Scope reviewed
Cost and failure behaviour.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-023 | info | cost | One `ps`, plus one `lsof` per soft-foundry process on macOS, per uncached answer; reused for 2 s. With five processes the answer took well under a second. | Bounded cost |
| REV-024 | info | failure | If `ps` is missing or fails, the data carries an `error`, the page says the list could not be read, and `soft-foundry ps` exits 1 with the reason. The other views are unaffected. | Operability |
| REV-025 | minor | usefulness | This is the first place an interrupted `phase run` is visible at all. `soft-foundry ci` and `change status` still say nothing about it. | Follow-up |

## Conformance
Conforms.
