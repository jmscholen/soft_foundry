# Operations Review

## Scope reviewed
What an operator or agent sees and does differently after this change: the install and uninstall commands, the doctor line, the three modes and their precedence, the log, the refusal and warning messages, and the documentation.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-023 | info | `README.md`, `AGENTS.md`, `.ai/README.md`, `.ai/policies/enforcement.yml` | The guard, its modes, its precedence, its limits (Bash deny-only, Read deny-only), and the install path are documented where an operator and an agent each read, and the policy file's own comment repeats the rules so a repository that never opens the README still sees them. | `.ai/rules/general.md` |
| REV-024 | minor | rollout | The shipped default is `warn`, so installing the hook changes no behaviour until a person flips the mode. The README says so, but there is no `soft-foundry guard status` or summary of the log (count of violations by skill) to help a person decide when to move to block. Follow-up: a `guard report` over `.soft-foundry/guard.log`. | `.ai/rules/observability.md` |
| REV-025 | info | this change record | This repository has not installed the hook into its own `.claude/settings.json`; doing so is a one-line commit the maintainer can make (or `--local` per machine). The next changes in this series would then run under the guard, which is the dogfooding the roadmap wants. | `.ai/rules/general.md` |
| REV-026 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan` although the CLI accepts only `--maturity scan`. Unchanged by this change. | Document rules |

## Conformance
Conforms.
