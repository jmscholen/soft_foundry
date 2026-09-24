# Security Review

## Scope reviewed
What the runner passes to a shell (a prompt built from the record and the control plane, plus arguments the person types after `--`), what it writes (two record fields), what the session can do (whatever the shell allows, bounded by the guard where installed), and the two trust decisions (the `executed_by` flag; the hook preferring a checkout).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-010 | info | `lib/soft_foundry/phase_runner.rb` `prompt` | The prompt interpolates the change slug (validated by `ChangeRecord`), the branch from `metadata.yml`, and phase and skill names from the control plane. A hostile branch name in `metadata.yml` could shape the prompt's text but not the shell's arguments: the prompt is one argument passed through `Process.spawn` without a shell. | `.ai/rules/security.md` |
| REV-011 | info | `lib/soft_foundry/cli.rb` `spawn_shell` | `Process.spawn(executable, *args)` with no shell interpolation; `--` arguments reach the shell verbatim as separate arguments. `Shell.resolve` finds the executable on PATH by name, the same as the interactive `shell` command. | `.ai/rules/security.md` |
| REV-012 | minor | trust model | `executed_by.fresh_context` is a field in a file the agent can write; the prompt tells it not to, the guard (if installed) does not deny the phase's own handoff, and the advisory believes the field. This is the same trust level as `vetted` and `human_decisions`: the record is what the merge reviewer reads. A signed or runner-only ledger would be the stronger design; out of scope. | `.ai/policies/human-boundaries.yml` |
| REV-013 | info | `lib/soft_foundry/hooks.rb` | Preferring `exe/soft-foundry` when `lib/soft_foundry.rb` is also present means a repository that vendors a file at that path could redirect its own hooks to code in its own tree. That is code the repository already runs on every commit through `ruby -Ilib`; no new trust is granted. | `.ai/rules/security.md` |

## Conformance
Conforms, with REV-012 stated as the design's honest scope.
