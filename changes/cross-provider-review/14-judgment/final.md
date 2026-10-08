# Final Judgment

## Outcome
**APPROVED_WITH_RESIDUAL_RISK**

REQ-XP-001 through REQ-XP-007 hold on the code at the judged commit. FIND-ATK-001 and REV-FUN-001 were fixed before this judgment and do not reproduce. The residuals below are the limits the intake and the implementation decision already chose, plus one warning that omits an unrecorded phase when no other shell exists. None of them is an open defect that more repository evidence would close.

## Commit judged
`2a493c7ef0fe856bb63ef2d276874e6a0a2117fb` (branch `change/cross-provider-review`).

The last commit that changes library, tests, README, or `.ai/` is `a963a27e4fc34e5200aa212bbc9d51d67e293cd1` (REM-002). `git diff a963a27..HEAD` and the worktree diff against that commit are empty for `lib/`, `test/`, `README.md`, `.ai/`, and `exe/`. `2c06a8e` records the rerun of verification, evaluation, and attack. `2a493c7` records the second review. Uncommitted edits at judgment time are `metadata.yml` (`current_phase: judge`) and this phase's handoff, neither of which is in the APP, TESTS, or INFRA path groups the staleness check uses.

## Requirements status
Acceptance bar is REQ-XP-001..007 in `00-intake/request.md`. Specify was skipped with a rationale in `metadata.yml`; those IDs were not relaxed.

| ID | Result |
| --- | --- |
| REQ-XP-001 | Met. `review` and `final-judgment` `skill.yml` both declare `prefer_different_provider_from: [implement, remediate]`. `Check#check_skill_contract` errors when an entry is not a lifecycle phase. |
| REQ-XP-002 | Met. `PhaseProvider.of` maps `anthropic`, `openai`, `xai`, `claude`, `codex`, `grok`, and `x.ai` case-insensitively, then falls back to `executed_by.shell`, then nil. An unrecognized provider name falls back to that shell (REM-002). A recognized name wins over a different shell, which is the recorded decision. |
| REQ-XP-003 | Met. With no `--shell`, `PhaseRunner#default_shell` picks the first installed shell, in claude, codex, grok order, on a provider none of the known named phases used, and prints one `shell:` or `! warn shell:` line. Known providers are still avoided when another named phase is unrecorded (REV-FUN-001 does not reproduce; EVAL-006 and the review probe). `--shell` skips the default. A skill with no preference still gets claude and no `shell:` line. |
| REQ-XP-004 | Met. `Advisory#same_provider_notices` names a completed review or judgment that resolved to the same provider as a completed named phase, and it does not fail the gate. Capitals are normalized. This review and this judgment both resolved to xAI; implementation and remediation recorded anthropic, so the advisory should not fire for either. |
| REQ-XP-005 | Met, and strengthened. `Gate#findings_explained_check` requires a non-empty `failure:` on every hash finding whose severity is not `minor` after strip and downcase, including a missing severity. REM-001 closed the `critical` / `high` bypass (FIND-ATK-001). The check stays structural, as the intake requires: `failure: n/a` passes. |
| REQ-XP-006 | Met. `.ai/skills/review/SKILL.md` says a finding with no concrete failure is minor at most, and that a defensive addition is not blocking or major unless the input that reaches the state is named. |
| REQ-XP-007 | Met across the three surfaces, not repeated in full in each. README states the preference, the default, the missing-provider warning, the unrecognized-name fallback, the advisory, and the `failure:` check. The `phase run` usage line states the default (review and judge pick an installed shell on a different provider from implementation and remediation; `--shell` includes grok). `.ai/schemas.md` states the `findings explained` check and the same-provider advisory. `SoftFoundry::VERSION` is `0.19.0`. |

Gates that this change must have, and what happened to each:

- Intake, implementation, verification, evaluation, attack, remediation, and review are complete.
- Discover, specify, threat model, and plan are pending and waived in `skipped_phases` with a non-empty rationale. Their handoffs were not treated as evidence.
- User documentation, FAQ index, and observability are pending and globally optional. They are not applicable here: REQ-XP-007 put the user-facing text in the README, the help line, and `.ai/schemas.md` during implementation; there is no separate FAQ corpus; `surfaces.observability` is false and there is no deployed service. Leaving them pending is what `skippable?` allows. This judgment did not fill them.
- Learning is the next phase. It is not a predecessor of judgment.

## Verification
Complete at `a963a27e4fc34e5200aa212bbc9d51d67e293cd1`, which is current for every code path of the judged commit. Result: pass.

`06-verification/evidence/tests.log` ends `481 runs, 3210 assertions, 0 failures, 0 errors, 0 skips`. The RED run at `eb3ace3` ends `10 runs, 24 assertions, 7 failures, 2 errors`. `soft-foundry check` passed. `ruby -wc` reported no warnings. `soft-foundry scan` reported 0 errors and 5 warnings, all in older records quoting attacks. CHECK-006 and CHECK-007 are inside the full suite and name RED commits `e62bc6e` and `b4dd692`. Those three RED commits are ancestors of `a963a27`, and each names `test/cross_provider_review_test.rb`. The five log hashes match `06-verification/evidence/manifest.yml`.

This judgment did not re-run the suite. No APP, TESTS, or INFRA file has changed since the run. Verification was performed by the implementing session (anthropic). The independent review later re-ran `CrossProviderReviewTest` (26 runs, 0 failures) and probed `default_shell`. That is the check on the shared-session evidence, not a second full suite.

## Evaluation
Complete at `a963a27`, current for the judged commit. Result: pass. EVAL-001 through EVAL-006 all pass in `07-evaluation/results.md`. The journey transcript, whose hash matches `07-evaluation/evidence/manifest.yml`, shows the codex `shell:` line, `--shell grok` with no `shell:` line, the missing-implementation warning that stays on claude, and EVAL-006: remediation unrecorded, implementation on anthropic, review on codex, with `! warn shell:` naming remediation. EVAL-005 keeps the line's meaning after non-ASCII bytes are deleted.

The manifest's `produced_by` still says "five journeys". The transcript and `results.md` contain six, including EVAL-006, and the hash is of that six-journey file. The label is stale. The evidence is not.

EVAL-OBS-001 stands: on this machine the default for an anthropic implementation is Codex, whose login has expired. Intake lists that as a non-goal. It is not a product failure.

## Attack
Complete at `a963a27`, current for the judged commit. Result: no remaining violation. Both cases are marked denied in `08-attack/results.md`. The transcript hash matches `08-attack/evidence/manifest.yml`.

ATTACK-001: severity in capitals, a whitespace `failure:`, and severity `critical` all fail `findings explained`. `failure: n/a` passes. That pass is the structural limit REQ-XP-005 states, recorded as a residual, not as an open finding. FIND-ATK-001 (a `critical` finding with no `failure:` passed at `0370e02`) was fixed in `53e4108` and does not reproduce.

ATTACK-002: a review handoff that writes a recognized provider other than the shell that ran does not draw the same-provider advisory. The same provider written in another casing still draws it. The silence is the decision that `resolved_model.provider` is agent-written and wins over `executed_by.shell`. It is a residual, not an unfixed bypass of a control the requirement demanded.

Attack, like verification and evaluation, was run by the implementing session. The notes say so. The preference for another provider applies to review and judgment, not to attack. The second review was a fresh xAI session and did not find a further case.

## Documentation
The optional product-documentation and FAQ-index phases are pending and were not required. The user-facing text REQ-XP-007 names is in the README section "A different provider for review and judgment", the `phase run` usage line, and `.ai/schemas.md` (the `findings explained` bullet and the same-provider advisory bullet). Review read those against the code after REM-002, including "the known ones are still avoided". This judgment read the same three surfaces. No separate FAQ was produced, and none was required.

## Observability
The observability phase is pending and was not required. `surfaces.observability` is false. There is no deployed service, dashboard, or alarm to add. The operator surface is the CLI: the `shell:` line, the `! warn shell:` line, the child's non-zero exit when a chosen shell fails to start, and the same-provider advisory after the phase completes. Operations review found those visible and did not file a finding. Nothing in this change is undetectable in production, because nothing is deployed.

## Review findings
Second review, fresh xAI session (`executed_by.fresh_context: true`, shell grok), complete at `2c06a8e9581c4a956abcb11a03168c11ed8dace3`. Provider xAI, which is not the anthropic provider recorded for implementation and remediation. Findings: none. Blocking: none.

The first review (also a fresh xAI session, commit `1c29ad0`) filed REV-FUN-001 (major). Remediation REM-002 fixed it at `a963a27`. The second review probed the mixed input (implementation known, remediation unrecorded; unrecognized name falling back to the shell) and reports that review now starts codex, not claude. This judgment read `PhaseRunner#default_shell` and `PhaseProvider.of` and the EVAL-006 transcript and agrees: the known provider is avoided, and an unrecognized name uses the recorded shell.

Deviations the review approved, and this judgment accepts:

- The RED test `test_remediation_counts_too` was corrected so review is complete before the judge dry-run. The assertion (grok, and the line naming both providers) was not weakened.
- Implementation wrote `.ai/` and `README.md`, which are outside that skill's write set. Those files are what REQ-XP-001, REQ-XP-005, REQ-XP-006, and REQ-XP-007 name, and no skill's write set covers them. The diff is those edits plus the library, the test, and the version. Review approved the content. The maintainer still accepts the control-plane diff at merge, as `05-implementation/deviations.md` says. That is not a human-boundary decision and it does not park the change.
- The `phase` usage line now names grok. That closes the earlier session-ledger usage gap in a file this change already edits.

Accessibility review conforms. The new lines carry `shell:` or `warn`, are ASCII, do not prompt, and do not depend on color or width. The Conformance section opens with "Conforms". Two go-live advisories still print, and neither fails the gate. The first is the designed one: specify was skipped, so no accessibility requirement was recorded. The second says the accessibility review declares conformance N/A. It does not. `Advisory` matches `\bN/A\b` anywhere in the Conformance section, and the review's last sentence is "this file does not declare conformance N/A". The matcher hits that denial. The lines are not inaccessible, and this judgment does not rewrite the review to silence the advisory.

Policy conformance is N/A with an examination: `surfaces.policy` is false, the profile records privacy, security, and terms as NOT_APPLICABLE, and the change collects, shares, and retains nothing new. No policy text change is owed. No human decision is requested. Infrastructure is N/A: no infrastructure-as-code tool, and the diff touches none.

## Residual risk
See `residual-risk.md`. They are accepted here. Nothing is left in `undischarged`: none of them waits on a production observation or another real-world confirmation. `unresolved_findings` is empty. `soft-foundry gate judge` on this handoff passes, with the two accessibility advisories named above and no same-provider advisory.

REV-FUN-001 and FIND-ATK-001 are closed. They are not residual risk.
