# Learning

## What this change taught us
- The one defect that blocked judgment (REV-001) was a sibling-path gap: the single-run path returned 2 when it marked a handoff blocked, and `parallel_run` discarded the same `mark_blocked` result. An implementation note said the parallel path "already counted blocked as a failure", which was true only of the printed tally, not the process exit status. The fix, test and rerun of four phases cost far more than a check of both callers at implementation time would have.
- Every minor finding that survived to judgment (REV-002 to REV-005, ATK-001 to ATK-004) is an input-shape gap: equals-form flags (`--risk=high`), a repeated flag, a string or mapping where a list is expected, a glob with a format character, a symlinked record file. Each was accepted as residual risk because the specified form is correct. The specification named the happy shape; the hostile shapes were found only by attack and review.
- The suite fails (12 failures, 1 error) when it inherits `SOFT_FOUNDRY_PHASE` from a phase session and passes with it unset (VER-001, REV-009). The same class as the local-environment-masks-CI lesson, in the other direction: the test environment leaks in from the runner.
- Guidance text that tells agents to build invisible characters with source escapes was shipped while `test/display_test.rb` still embeds them raw (REV-007). The change did not follow its own new guidance.
- Evidence reruns after remediation were scoped well: verification, evaluation, attack and review each recorded why the rerun was current, and judgment checked `git diff 44efb99..HEAD` was empty for code paths.

## Reviewer/evaluator/attack findings worth generalizing
- REV-001 (major): a fix or behavior implemented on one command path needs the same behavior checked on every sibling path that calls the same helper and returns an exit status.
- REV-002 / ATK-004: option parsing that accepts only the spaced form silently ignores the equals form and a repeated flag. Silent ignore is worse than refusal because the record is created without the value the person typed.
- REV-003 / ATK-001: a summary that prints "none" for an unexpected value shape hides what a gate still reports. Display code should print the raw (escaped) value or "unreadable", not "none".
- REV-004 / ATK-002: a lint that accepts a glob that can never match gives false assurance for a protection check.
- VER-001 / REV-009: tests that read runner-set environment variables must clear them in setup.
- REV-007: raw invisible characters in test sources conflict with the scan guidance the change itself added.

## Proposed deterministic checks
- A check that fails `test/` sources containing raw bidirectional, zero-width or line-separator characters (REV-007). Overlaps the existing content scan, which may exempt tests; confirm against `.ai/policies/content-scan.yml` before proposing it.
- A test-helper level guard that clears `SOFT_FOUNDRY_PHASE` and related runner variables for the whole suite (VER-001). This is a `test/` change, not a control-plane one.

## Proposed rule changes
See `proposed-rules.md`: sibling-path check for exit status, option-form parity (spaced, equals, repeated) in CLI specifications, and summary views must not collapse an unexpected shape to "none".

## Proposed harness evals
See `proposed-evals.md`: a gate case for blocked parallel exit, and a live case where the same defect is planted on one of two sibling paths.

## Not proposed
- Nothing here argues for weakening or waiving any phase. The review-and-judgment path worked as designed: judgment returned BLOCKED once, remediation fixed it, and every phase was rerun.
- No instinct is recorded for REV-006 (unlinted `tracks.forced_by_risk` key); it is a one-off lint gap and the shipped workflow agrees.
