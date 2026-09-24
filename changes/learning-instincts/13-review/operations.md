# Operations Review

## Scope reviewed
What an operator or agent sees and does differently: a fourth required learning file, the `instincts valid` gate line, `learn list`, `learn promote` and its refusal, the policy threshold, `learned.md` in the baseline rules.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-018 | info | `README.md`, `.ai/schemas.md`, `.ai/rules/README.md`, the learning skill, the template and policy comments | Documented where an operator and an agent each read; the template comment says who promotes and that an empty list is valid. | `.ai/rules/general.md` |
| REV-019 | info | existing records | Records scaffolded before this change have no `instincts.yml`; their learning phases are pending or skipped, so nothing changes for them until one completes learning, at which point the file must be created from the template. This record did exactly that. | `.ai/schemas.md` |
| REV-020 | minor | rollout | Nothing reminds a person that instincts above the threshold are waiting to be promoted; `change status` or `ci` could print a one-line count. Follow-up. | `.ai/rules/observability.md` |
| REV-021 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan`. Unchanged. | Document rules |

## Conformance
Conforms.
