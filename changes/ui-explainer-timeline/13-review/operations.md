# Operations Review

## Scope reviewed
Cost of the new views.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-020 | info | workflow view | One request for about 23 KB, answered in about 16 ms and reused for 2 s; polled every 5 s while that view is open. | Bounded cost |
| REV-021 | info | change view | No extra request: timeline and spend arrive with the change. The workflow is fetched once per page load for the descriptions. | Bounded cost |

## Conformance
Conforms.
