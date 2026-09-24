# Operations Review

## Scope reviewed
What an operator or agent sees and does differently after this change: `phase run` and its refusals, `--dry-run`, the guard warning, `executed_by` in handoffs, the fresh-context advisory on existing open records, the branch-aware staleness detail in `gate`/`ci` output, and the hook ordering.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-022 | info | `README.md`, `AGENTS.md`, `.ai/schemas.md`, the handoff template | The runner, the field, the advisory, and the staleness rule are documented where an operator and an agent each read; the template comment says who writes `executed_by`. | `.ai/rules/general.md` |
| REV-023 | info | open records in this repository | `runtime-guard` and this change now carry the fresh-context review advisory on every gate run, because both reviews were performed in the implementing session. That is the advisory doing its job; the next change should run `phase run review` and be the first without it. | `.ai/rules/general.md` |
| REV-024 | minor | rollout | Anyone with the pre-commit hook installed before this change is still running the PATH-first script until they rerun `soft-foundry hooks install`; nothing tells them. Follow-up: `doctor` could compare the installed hook's text with `Hooks::SCRIPT` and say "outdated". | `.ai/rules/observability.md` |
| REV-025 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan`. Unchanged by this change. | Document rules |

## Conformance
Conforms.
