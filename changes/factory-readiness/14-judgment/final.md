# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
f18691e9065818dee2929bfa5eb8b7f82c26aefd (HEAD). `git diff 50a4506 HEAD -- . ':!changes'` is empty: application, test, and control-plane files are identical to the commit verification ran at (50a4506, code from GREEN b0bb901). Only change records were added since.

## Requirements status
The change's acceptance criteria AC-FR-001 to AC-FR-021 are accounted for by verification (568 runs, 0 failures, default and C locale; check and eval pass) and evaluation (journeys EVAL-001 to EVAL-010; no behavioural failure at ac3e8cf). Not exercised as user journeys but covered by verification: AC-FR-002, 003, 004, 012, 013 and the positive side of AC-FR-006 (EVAL-F3). AC-FR-021 (documentation read against code) holds for behaviour; the README text owed is open (see Documentation).

## Verification
06-verification at 50a4506: both suites 568 runs, 3861 assertions, 0 failures; check 16 phases/17 skills no errors; eval 12 passed, 0 failed, 1 skipped (live). `ci` failed only on staleness of verify/evaluate/attack, which the later reruns cleared. An earlier intermittent live-case failure under load did not recur and was never root-caused; recorded as residual.

## Evaluation
07-evaluation rerun at ac3e8cf after REM-006: EVAL-F7 (major) closed; no journey failed on behaviour. Live eval fails on a default invocation without shell arguments (EVAL-F1) and passes with them. Planted-case journeys were not re-run by that skill (EVAL-F6); verification owns them and eval code is unchanged.

## Attack
08-attack at 9806b2b (fifth round): eleven single-command tampers of the guard configuration are restored and refused; ATK-F11 and overlapping-call re-baselining confirmed fixed. Remaining: ATK-F10 remainder (detached writer, policy and baseline rewritten together, weak policy committed with baseline deleted), ATK-F12, ATK-F9, ATK-F3. All are same-user-with-shell routes accepted as residual in REM-004/005; no new finding.

## Documentation
10-user-documentation and 11-faq-index are pending, not run and not waived (skipped_phases is empty). The change is a CLI/harness change whose user-facing text is the README, which the remediations show as owed and which no skill may write (REV-001, REV-010, EVAL-F5). This is not a hidden gap: it is an open condition, listed below, for the maintainer to discharge before merge.

## Observability
12-observability is pending, not waived. `surfaces.observability: false`; the change is a local CLI with no service. The guard's tamper log line is the relevant signal and is exercised by tests. Noted per the review's request.

## Review findings
13-review at a9fac32: no blocking findings. REV-001 (major): README guard section, enforcement.yml header, and this repository's hook settings (no PostToolUse entry, so the post-call restore is inactive here until `soft-foundry hooks install --claude` is rerun) are owed to the maintainer; doctor does not detect a missing PostToolUse entry. REV-002 (major): same-user residual routes, decided here as accepted (below). REV-003 to REV-011 minor, all carried into residual risk. Nothing requires an implementation change, so nothing returns to verify.

## Residual risk
See residual-risk.md. Judgment decision on REV-002/ATK-F10: accepted. The repository has no OS sandbox by prior decision; these routes leave traces (guard log, git history, PR diff) that review reads. Conditions of approval: before merge the maintainer applies the owed README/enforcement.yml text, reruns `hooks install --claude` here, and decides whether to run the documentation phases or record the README edit as the documentation of record.
