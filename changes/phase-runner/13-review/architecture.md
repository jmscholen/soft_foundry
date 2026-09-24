# Architecture Review

## Scope reviewed
The split between `PhaseRunner` (refusal, prompt, launch, stamps) and the CLI (options, spawn, gate, exit codes); the reuse of `effective_predecessor`, `skippable?`, `Gate`, `Advisory`, and `Hooks.claude_installed?`; the new git primitives; the hook ordering.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-006 | info | `lib/soft_foundry/phase_runner.rb` | The runner knows how to build a launch and stamp a handoff; it does not spawn. The CLI spawns through an injectable `runner:` so tests drive a fake without a process. Same shape as `shell:` and `pr_discharge:`. | `.ai/rules/architecture.md` |
| REV-007 | info | `lib/soft_foundry/phase_runner.rb` `refusal` | The predecessor rule is the gate's own (`effective_predecessor` with `skippable?`), so the runner and the gate cannot disagree about what may start. | `.ai/rules/architecture.md` |
| REV-008 | info | `lib/soft_foundry/git.rb` | `changed_between` and `branch_tip` are two small primitives beside `changed_since`; the branch-awareness lives in the gate, where the record is known. | `.ai/rules/architecture.md` |
| REV-009 | minor | `lib/soft_foundry/cli.rb` `phase` | The command method is long (options, refusal, warning, dry run, spawn, gate). It reads top to bottom and each block is a requirement, but a `PhaseRunner#run` that takes a spawner and returns a result would let the CLI shrink to printing. Follow-up. | `.ai/rules/architecture.md` |

## Conformance
Conforms.
