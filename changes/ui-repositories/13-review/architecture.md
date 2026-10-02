# Architecture Review

## Scope reviewed
Where the new responsibilities sit.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-008 | info | `UI::Server` | The registry, ids, and token are the server's; `Snapshot` and `Processes` stay ignorant of them and are constructed per repository. | Domain not in the delivery mechanism |
| REV-009 | minor | `Processes#snapshot(with_roots:)` | A flag that changes what is safe to publish. It is tested both ways, and the server strips the roots, but a caller that forgets would leak paths. A separate internal method would make the safe form the only public one. | Least surprise |
| REV-010 | minor | `app.js` | One 900-line file holding five views, routing, polling, and token handling. It has no modules because there is no build step; splitting it into a few files served the same way would help, and would make testing parts of it possible. | Simplicity |
| REV-011 | info | `Snapshot#overview` | Reuses `summary`; no gating. | Reuse |

## Conformance
Conforms.
