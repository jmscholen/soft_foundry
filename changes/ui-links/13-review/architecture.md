# Architecture Review

## Scope reviewed
Where the reference logic sits.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-007 | info | `app.js` | Four makers and one describer; every call site goes through them, and a count in verification checks that no plain anchor to a repository address was added elsewhere. | Single source |
| REV-008 | minor | `app.js` | Now about 1,050 lines in one file. The split proposed in ui-repositories is more overdue. | Simplicity |

## Conformance
Conforms.
