# Security Review

## Scope reviewed
- The new skill's `permissions.yml` (`.ai/skills/code-quality/`).
- The `06a-code-quality/**` deny-write additions in other skills.
- Remediation's read access to the new directory.
- The `fresh session recorded` check applied to quality.
- The attack threat model in `.ai/skills/adversarial-testing/SKILL.md`.

AC-004 is tested and passes in this session's run. The remediation diff (`818165e..1650d93`) adds no permission, path or exposure.

I also read the record for what this change's own phases actually did. Remediation's summary says it edited `.ai/templates/repository.yml`, a control-plane file in its `deny_write`, under the maintainer's local warn override.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-006 | minor | `lib/soft_foundry/hooks.rb` (`GUARD_AFTER_COMMAND`) | Outside this change, still open. When the shell's working directory is a subdirectory, the PostToolUse hook writes a stray `.ai/policies/enforcement.yml` there and logs a false tamper. It happened again in this session, on a `cd` into the change record. Untracked `changes/code-quality-gate/.ai/policies/enforcement.yml` remains. The copies verification left (VER-005) are already gone. | A careless `git add -A` commits the stray policy copies. | Follow-up; `outside_change` |
| REV-009 | minor | `.ai/templates/repository.yml:18-23` | Remediation wrote a control-plane file that its `permissions.yml` denies. It did so under the maintainer's local warn override, and the summary discloses it. The edit is comment-only. This change's subject is the control plane itself, so the fix needed that file's wording to stay true. | None in behaviour. The record shows a phase writing outside its write set; it is disclosed and approved by the maintainer. | Phase boundaries (AGENTS.md 7) |

## Conformance
Conforms. The phase cannot write code, tests, docs, the control plane or other phases' evidence, and cannot read harness evals (REQ-003). Under the attack threat model, nothing here is reachable by an outside party.
