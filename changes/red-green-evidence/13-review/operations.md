# Operations Review

## Scope reviewed
What an operator or agent sees and does differently: the two optional fields, the `red evidence` line on every verification gate, the advisory on every open feature record without RED evidence, and the rule now asking for test-first commits.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-018 | info | `README.md`, `.ai/schemas.md`, `.ai/rules/testing.md`, the two skills, the template | Documented where an operator and an agent each read, and the template comment says exactly what the gate will check. | `.ai/rules/general.md` |
| REV-019 | info | open records in this repository | `runtime-guard` and `phase-runner` now carry `! warn verification:` on every gate run: neither was done test-first. This record is the first in the repository whose verification gate prints `✓ pass red evidence`. | `.ai/rules/general.md` |
| REV-020 | minor | rollout | The testing rule now asks for a RED commit, but nothing in `change new` or the implementation template reminds an agent at the moment it starts coding; the advisory arrives at verification, after the fact. Follow-up: a line in `05-implementation/log.md`'s template ("RED commit: ...") so the trail is started where the work happens. | `.ai/rules/observability.md` |
| REV-021 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan`. Unchanged. | Document rules |

## Conformance
Conforms.
