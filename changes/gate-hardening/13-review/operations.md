# Operations Review

## Scope reviewed
Failure, recovery and cost behaviour of the CLI: a commit refused by the pre-commit hook (metadata left advanced, rerun completes), a killed seal, gate wall time, and git subprocess count. `surfaces.observability: false`; there is no service, metric or alarm. Read 07-evaluation EVAL-017/EVAL-019 and the `phase_seal.rb` failure path.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-010 | minor | `phase_seal.rb` commit path (ATK-009 residue) | A seal killed mid-commit leaves `.git/index.lock`, and the user must delete it by hand; no message says so. | After a kill, the next `phase seal` fails with git's lock error and no next action from Soft Foundry. | REQ-032 |
| REV-011 | minor | ATK-003 | A manual `phase seal` fired while a `phase run` session is open yields two Record commits. Both are consistent. | History carries a duplicate seal commit; no gate result is wrong. | REQ-001 |

## Conformance
Conforms with advisories. Recovery after a refused commit is by rerun, as specified. Measured cost: `gate all` 1.42 s against 1.18 s for the pre-change gem (ratio 1.20 against the bound of 2), 71 git calls against 64. 902 tests pass.
