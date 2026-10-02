# Architecture Review

## Scope reviewed
Where the new logic sits.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-006 | info | `Snapshot#spend` | The cap comparisons are in the data layer; the page draws words from booleans. | Domain not in the delivery mechanism |
| REV-007 | minor | `app.js` `waysBack`, `CONDITIONS` | The page turns transition keys (`on_blocking_findings`) into phrases and decides which edges are non-linear. That is interpretation of the workflow and would sit better in the snapshot. | Single source of truth |
| REV-008 | info | `app.js` | The workflow view reuses the strip and panel styles; no new component. | Simplest design |

## Conformance
Conforms.
