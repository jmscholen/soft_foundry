# Functional Review

## Scope reviewed

Requirements REQ-XP-001 through REQ-XP-007 in `00-intake/request.md`. Specify was skipped; those IDs are the acceptance bar. Decisions and deviations in `05-implementation/` and the remediation record in `09-remediation/summary.md` were read. This review does not treat an earlier review's conclusion as evidence.

Code reviewed at `2c06a8e9581c4a956abcb11a03168c11ed8dace3`. `git diff a963a27..HEAD` is empty for `lib/`, `test/`, `README.md`, `.ai/`, and `exe/`, so this is the tree verification, evaluation, and attack bound (481 runs, 0 failures; RED commits `eb3ace3`, `e62bc6e`, and `b4dd692`).

Behavior checked in `PhaseProvider.of`, `PhaseRunner#default_shell`, `CLI#phase`, `Advisory#same_provider_notices`, `Gate#findings_explained_check`, and the `prefer_different_provider_from` lint in `Check`. A read-only probe drove `default_shell` through the existing fixture (throwaway repositories) for the mixed, both-known, unrecognized-name, and no-alternative inputs. That run also executed `CrossProviderReviewTest`: 26 runs, 162 assertions, 0 failures (the probe class inherited the tests, so the file ran twice). The full suite was not re-run.

## Findings

None.

## Deviations

1. **RED test setup, approved.** In `0370e02`, `test_remediation_counts_too` completes review before the judge dry-run. At `eb3ace3` the runner refused `phase run judge` because review was still pending, so the assertion never ran. The assertion is unchanged: grok, and the line naming both providers. Fixture setup, not a weaker expectation under `.ai/rules/testing.md`.

2. **Control-plane writes, approved.** See the architecture review. The files are the ones REQ-XP-001, REQ-XP-005, REQ-XP-006, and REQ-XP-007 name.

3. **Usage text names grok.** `CLI#phase` says `--shell claude|codex|grok`. Session-ledger REV-FUN-002 is closed by that line. Not re-filed.

## Requirement results

**REQ-XP-001.** `.ai/skills/review/skill.yml` and `.ai/skills/final-judgment/skill.yml` both declare `prefer_different_provider_from: [implement, remediate]`. `Check#check_skill_contract` errors when an entry is not a lifecycle phase. The test covers a `nonsense` entry.

**REQ-XP-002.** `PhaseProvider.of` strips and downcases `resolved_model.provider` and maps `anthropic`, `openai`, `xai`, `claude`, `codex`, `grok`, and `x.ai` (probe: `"  X.AI  "` and `"Claude"`). A blank provider falls through to `executed_by.shell`. An unrecognized provider falls through to that shell (`"claude-opus"` with shell `claude` is anthropic). With no shell it is nil. A recognized provider wins over a different shell (`openai` with shell `claude` stays openai), which is the recorded decision, not a miss.

**REQ-XP-003.** Holds on the inputs below. `--shell` skips `default_shell`. A phase whose skill has no preference still gets claude and prints no `shell:` line.

| Input | Installed | Choice |
| --- | --- | --- |
| Implementation anthropic, remediation not recorded | claude, codex, grok | codex, and `! warn shell:` names remediation and implementation's anthropic |
| Implementation not recorded, remediation anthropic | claude, codex, grok | codex, and the warning names implementation |
| Both anthropic, including remediation `claude-opus` with shell `claude` | claude, codex, grok | `shell: codex (implementation ran on anthropic, remediation on anthropic; …)` |
| Implementation anthropic, remediation xai, only claude | claude | claude, `! warn shell:` says no installed shell is on another provider |
| Implementation anthropic, remediation not recorded, only claude | claude | claude, same no-alternative warning. The choice is the one the requirement requires; the warning does not also name the unrecorded phase. Noted under residual concerns, not a finding: the sentence is still true, and no other shell exists. |
| Implementation recorded `openai` while its shell is `claude`, remediation `xai` | all three | claude. The recognized provider is what is avoided. See the residual. |

REV-FUN-001 does not reproduce. The first review's two probes (remediation provider null with no shell; remediation `claude-opus` with shell `claude`, all three shells installed) now start codex, not claude.

**REQ-XP-004.** A completed review or judgment whose resolved provider equals a completed named phase's provider produces the advisory and does not fail the gate. The probe with review on openai and remediation on openai named remediation only. A blank review provider with shell `codex` still resolves to openai and the advisory still fires. Capitals on the provider field are normalized.

**REQ-XP-005.** `findings_explained_check` requires a non-empty `failure:` on every hash finding whose severity is not `minor` after strip and downcase, including a missing severity. ` minor ` and `Minor` are exempt. An empty string and whitespace fail. The seven review templates have a "Failure it prevents" column, including `policy-conformance.md`. The handoff template and `.ai/schemas.md` document the field. The check stays structural: `failure: n/a` passes, as the intake requires.

**REQ-XP-006.** `.ai/skills/review/SKILL.md` says a finding with no concrete failure is minor at most, and that a defensive addition is not blocking or major unless the input that reaches the state is named.

**REQ-XP-007.** `SoftFoundry::VERSION` is `0.19.0`; `soft_foundry.gemspec` reads that constant. README "A different provider for review and judgment" and "Findings name the failure they prevent", the `phase run` usage line, and `.ai/schemas.md` (the `findings explained` bullet and the same-provider advisory bullet) describe the preference, the default, the unrecognized-name fallback, the advisory, and the `failure:` check. The README matches the code after REM-002, including "the known ones are still avoided".

## Conformance

Conforms. REQ-XP-001 through REQ-XP-007 hold on the inputs the requirements name, including the mixed input REV-FUN-001 filed. No finding.
