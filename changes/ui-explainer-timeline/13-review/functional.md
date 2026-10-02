# Functional Review

## Scope reviewed
The additions to `snapshot.rb`, `app.js`, `app.css`, `index.html`, the five new tests, and the evaluation evidence, against REQ-UX-001..007.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | all | Each requirement is implemented; the data-layer parts have tests and the page parts a recorded browser observation. | REQ-UX-001..007 |
| REV-002 | minor | `Snapshot#timeline` | An event with an unusable time disappears without trace. A count of "events without a usable time" in the data would let the page say so. | REQ-UX-004 |
| REV-003 | minor | `app.js` `spendSection` | Token counts are printed without thousands separators (421000). | Readability |
| REV-004 | minor | `app.js` | Still no automated test that runs the page (carried from ui-server REV-006); this change adds about 170 lines to it. | `.ai/rules/testing.md` |
| REV-005 | info | `app.js` workflow fetch | If the workflow request fails, changes are simply shown without check descriptions. | Degrades safely |

## Conformance
Conforms, with minor findings.
