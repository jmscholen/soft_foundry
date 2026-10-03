# Functional Review

## Scope reviewed
The two fixes, their tests, and the real-release transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | both fixes | Each was shown failing against the real release, then passing. | REQ-UPD-007..009 |
| REV-002 | major (process) | `update-from-github` | Its evaluation ran the install path from inside this repository, where the shim resolves correctly, and against a source tarball named by its address. Neither defect could show. The real test was named as owed and found both. | Evaluation on the real path |
| REV-003 | minor | installed 0.17.0 | Cannot self-update; a one-time crossover from a checkout. | Operability |

## Conformance
Conforms.
