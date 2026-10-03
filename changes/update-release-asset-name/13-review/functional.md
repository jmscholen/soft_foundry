# Functional Review

## Scope reviewed
The two fixes, their tests, and the real-release transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | info | both fixes | Each was shown failing against the real release, then passing. | REQ-UPD-007..009 |
| REV-002 | major (process) | `update-from-github` | Its evaluation ran the install path from inside this repository, where the shim resolves correctly, and against a source tarball named by its address. Neither defect could show. The real test was named as owed and found both. | Evaluation on the real path |
| REV-011 | info | `test/ui_server_test.rb` | The flaky test is found and fixed: a timing bound of 2 s on a request that includes gating the board, under load. The bound is now the read timeout, which is what the test is about. Closes ui-processes REV-029 and ui-repositories' note on the unattributed failure. | `.ai/rules/testing.md` |
| REV-003 | minor | installed 0.17.0 | Cannot self-update; a one-time crossover from a checkout. | Operability |

## Conformance
Conforms.
