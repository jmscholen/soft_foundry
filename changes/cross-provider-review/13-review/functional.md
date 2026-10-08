# Functional Review

## Scope reviewed

Requirements REQ-XP-001 through REQ-XP-007 in `00-intake/request.md`. Specify was skipped; those IDs are the acceptance bar. Decisions and deviations in `05-implementation/` were read and are answered below.

Code reviewed at `2bcd186a2e6b97178c196bef26a05d7ec29100ed`. `git diff 53e4108..HEAD` is empty for `lib/`, `test/`, `README.md`, and `.ai/`, so this is the same tree verification, evaluation, and attack bound (479 runs, 0 failures; RED commits `eb3ace3` and `e62bc6e`).

Behavior checked in `PhaseProvider.of`, `PhaseRunner#default_shell`, `CLI#phase`, `Advisory#same_provider_notices`, `Gate#findings_explained_check`, and the `prefer_different_provider_from` lint in `Check`. A Ruby probe called `default_shell` with all three shells installed. The full suite was not re-run.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-FUN-001 | major | `PhaseRunner#default_shell` (`lib/soft_foundry/phase_runner.rb`); `PhaseProvider.of` makes the second input nil | If any named phase has no resolvable provider, the method returns the first installed shell immediately and never applies the providers it did resolve. | Implementation complete with `resolved_model.provider: anthropic`, remediation complete with `provider: null` and no `executed_by.shell`, claude, codex, and grok installed, `phase run review` with no `--shell`: the probe started `claude` and printed `! warn shell: the provider of remediation is not recorded, so review runs on claude`. Claude is anthropic, the same provider as implementation. REQ-XP-003 requires the first installed shell that differs from every known provider, which is codex. The same probe with remediation `provider: claude-opus` and `executed_by.shell: claude` also started claude: `PhaseProvider.of` returns nil for an unrecognized provider and does not read the shell, and the warning still says the provider is not recorded. `phase run judge` uses the same method. Both-known and implementation-only inputs still pick grok and codex. | REQ-XP-003 (differ from every known provider). `.ai/rules/errors.md` (a fallback must not turn a known collision into a warning about a different phase). `.ai/rules/general.md` (satisfy the requirement). |

## Deviations

1. **RED test setup, approved.** In `0370e02`, `test_remediation_counts_too` gained `complete_phase!(record, "review")` before the judge dry-run. At `eb3ace3` the runner refused `phase run judge` because review was still pending, so the assertion never ran. The assertion is unchanged: grok, and the line naming both providers. That is fixture setup, not a weaker expectation under `.ai/rules/testing.md`.

2. **Control-plane writes, approved.** See the architecture review. The files are the ones REQ-XP-001, REQ-XP-005, REQ-XP-006, and REQ-XP-007 name.

3. **Usage text names grok.** `CLI#phase` now says `--shell claude|codex|grok`. Confirmed in the source. Session-ledger REV-FUN-002 is closed by that line. Not re-filed.

## Requirement results

**REQ-XP-001.** `.ai/skills/review/skill.yml` and `.ai/skills/final-judgment/skill.yml` both declare `prefer_different_provider_from: [implement, remediate]`. `Check#check_skill_contract` errors when an entry is not a lifecycle phase. The test covers a `nonsense` entry.

**REQ-XP-002.** `PhaseProvider.of` downcases and strips `resolved_model.provider` and maps `anthropic`, `openai`, `xai`, `claude`, `codex`, `grok`, and `x.ai`. An empty provider falls through to `executed_by.shell`. A provider string that is not in the map returns nil and does not read the shell. The nil is what REV-FUN-001 then treats as "not recorded". Blank-then-shell is what REQ-XP-002 asks for; a present unrecognized string is not in the test, which only asserts nil when no shell is set.

**REQ-XP-003.** Holds when every completed named phase has a resolvable provider, when none of them do (warn, first installed shell), and when no installed shell differs (warn, that shell). `--shell` skips `default_shell`. A phase whose skill has no preference still gets claude with no `shell:` line. It does not hold for the mixed input in REV-FUN-001. README describes the unknown case as "implementation's provider is not recorded", which matches the decision and the single-phase test, not the early return that also fires for remediation.

**REQ-XP-004.** A completed review or judgment whose resolved provider equals a completed named phase's provider produces the advisory and does not fail the gate. Capitals are normalized (`xAI` against `anthropic` does not match). A nil provider on either side does not match, which is the recorded residual when the agent writes a provider the map does not know.

**REQ-XP-005.** `findings_explained_check` requires a non-empty `failure:` on every finding whose severity is not `minor` after strip and downcase, including a missing severity. `Minor` is exempt. The seven review templates have a "Failure it prevents" column, including `policy-conformance.md`. The handoff template and `.ai/schemas.md` document the field. The check stays structural: `failure: n/a` passes, as the intake requires.

**REQ-XP-006.** `.ai/skills/review/SKILL.md` says a finding with no concrete failure is minor at most, and that a defensive addition is not blocking or major unless the input that reaches the state is named.

**REQ-XP-007.** `SoftFoundry::VERSION` is `0.19.0`; `soft_foundry.gemspec` reads that constant. README "A different provider for review and judgment" and "Findings name the failure they prevent", the `phase run` usage line, and `.ai/schemas.md` describe the preference, the default, the advisory, and the `failure:` check. The README's unknown-provider sentence is the decision's sentence; the code is wider, which is REV-FUN-001, not a separate documentation miss.

## Conformance

Conforms with a major finding. REQ-XP-001, REQ-XP-002 for the names and the blank-provider fall-through, REQ-XP-004, REQ-XP-005, REQ-XP-006, and REQ-XP-007 hold. REQ-XP-003 holds on the inputs the tests name and fails on the mixed input in REV-FUN-001.
