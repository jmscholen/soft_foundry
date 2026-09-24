# Infrastructure Review

## Scope reviewed
No Infrastructure as Code is present in or modified by this change. The only deployment artifact is the gem. The new `.ai/policies/enforcement.yml` ships through the gemspec's `.ai/**/*` glob; `test/installer_test.rb` and `test/installer_source_test.rb` still pass. The hook command written into `.claude/settings.json` has the same two-way fallback as the pre-commit hook (gem on PATH, else a checkout of this repository).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-021 | info | `lib/soft_foundry/hooks.rb` `GUARD_COMMAND` | In a governed repository that is not a Soft Foundry checkout and has no gem on PATH, the hook command runs nothing and Claude Code sees exit 0: silently unguarded. `doctor` reports the hook as installed because the entry exists. Follow-up: `doctor` could also check that `soft-foundry` resolves on PATH. | `.ai/rules/infrastructure.md` |
| REV-022 | info | `.ai/policies/enforcement.yml` | Ships with `warn`; a repository that wants `block` changes one line under `.ai/policies/`, which is protected from every skill's write set, so an agent cannot lower it through a record. | `.ai/policies/skill-permissions.yml` |

## Conformance
N/A: no infrastructure is present or modified. Examined the packaging path and the hook's fallback behaviour.
