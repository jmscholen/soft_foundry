# Security Review

## Scope reviewed
Whether naming by asset weakens the version check.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-005 | info | asset name | The name comes from the release's JSON, matched against `soft_foundry-<version>.gem` at parse time and again, with `File.basename`, before install; a name with a path in it cannot escape the temporary directory. The three-way agreement stands. | Dependency integrity |
| REV-006 | info | `bindir/gem` | A fixed path next to the running Ruby; no PATH lookup. | Injection |

## Conformance
Conforms.
