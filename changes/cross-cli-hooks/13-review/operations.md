# Operations Review

## Scope reviewed
What an operator sees: `hooks install --codex` and its trust note, the combined doctor line, `phase run --shell grok`, the runner's per-shell warnings.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-017 | info | README, AGENTS.md, help text, install output | The Codex path and the Grok limitation are stated where an operator and an agent each read, and at the moment of install. | `.ai/rules/general.md` |
| REV-018 | minor | Codex trust | Nothing in Soft Foundry can confirm the hook is trusted in Codex; a person must run `/hooks`. A `doctor` note that the Codex line means "written, trust unknown" would be more honest. Follow-up. | `.ai/rules/observability.md` |
| REV-019 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan`. Unchanged. | Document rules |

## Conformance
Conforms.
