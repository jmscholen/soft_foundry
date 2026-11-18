# Security Review

## Scope reviewed
The new skill's `permissions.yml` (`.ai/skills/code-quality/`). The deny-write additions in other skills: every skill whose `deny_write` lists phase directories now lists `06a-code-quality/**`. Evaluation, verification, intake and the other skills that only allowlist their own directory need no entry, because their `write` set does not reach it. Also read: remediation's read access to the new directory, the gate's `fresh session recorded` check now applied to quality, and the attack threat model in `.ai/skills/adversarial-testing/SKILL.md`. AC-004 (the guard allows only the phase's own directory and refuses harness-eval reads) is tested and passes.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-006 | minor | `lib/soft_foundry/hooks.rb:88` (`GUARD_AFTER_COMMAND`) | Outside this change. When a shell call leaves its working directory in a subdirectory, the PostToolUse hook falls back to the global `soft-foundry`, resolves the repository from that directory, and writes a "restored" `.ai/policies/enforcement.yml` under the subdirectory, reporting a tamper. It happened twice in this review session, leaving untracked files at `.ai/skills/review/.ai/policies/enforcement.yml` and `changes/code-quality-gate/.ai/policies/enforcement.yml`. This session could not remove them (the deletion was refused). VER-004 and the implementation log saw the same. | A `cd` inside the repository makes the guard report a false tamper and leaves stray copies of the policy file in the tree, which a careless `git add -A` would commit. | Follow-up; `outside_change` |

## Conformance
Conforms. The phase cannot write code, tests, docs, the control plane or other phases' evidence, and cannot read harness evals (REQ-003). Under the attack threat model, nothing here is reachable by an outside party. The tool exposes no network surface.
