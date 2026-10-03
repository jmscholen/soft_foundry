# Functional Review

## Scope reviewed
The link makers, `linkify`, `describeRef`, `located`, the tooltip handling, every call site, the static test, and the browser observations, against REQ-LINK-001..004.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | all | Every kind of reference the intake names is a link with a popup that ends in a path, observed on the real machine. | REQ-LINK-001..003 |
| REV-002 | minor | `linkify` | Recognises only `NN-name` directory forms. A phase named by id in free text ("the verify gate") stays text, by decision; a slug named in free text is not linked at all. | REQ-LINK-001 |
| REV-003 | minor | `describeRef` for a gate elsewhere | Says the path but not the state (EVAL-NOTE-001). Fetching that change on hover would make it complete at the cost of a request. | REQ-LINK-002 |
| REV-004 | minor | board headers | 32 extra tab stops per board (EVAL-NOTE-002). | REQ-LINK-004 |
| REV-005 | major | testing | No RED commit; the only test is static; the behaviour rests on the browser pass. The page still has no test that runs it, the finding carried since ui-server. | `.ai/rules/testing.md` |
| REV-006 | info | popups | Built from data already on the page; no request, no new route. | Constraints |

## Conformance
Conforms, with REV-005 the standing gap.
