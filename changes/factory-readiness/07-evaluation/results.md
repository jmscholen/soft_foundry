# Evaluation Results

Re-run at HEAD after remediation REM-003 (the guard follows a chained cd back to the root, expands braces, refuses what it cannot decide instead of raising, and guards Grep and Glob; the hook matcher now includes them). The earlier evaluation was bound to 98b336f and went stale; every journey below was run again at this commit in fresh scratch repositories.

Commit SHA: 9307b23a6a7560d41bea4a1a31eba76c708c348c

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | AC-FR-019, AC-FR-020 | pass | evidence/rails-install-profile-change-new.txt, evidence/eval-clean-and-live-refusals.txt |
| EVAL-002 | AC-FR-007, AC-FR-008, AC-FR-019 | pass (18 calls refused or allowed as expected, including 7 REM-003 routes) | evidence/rails-guard-decisions.txt |
| EVAL-003 | AC-FR-009, AC-FR-010, AC-FR-011, AC-FR-014 (partly), AC-FR-020 | pass | evidence/eval-failure-modes.txt, evidence/eval-clean-and-live-refusals.txt |
| EVAL-004 | AC-FR-015 | pass on the second run, fail on the first | evidence/live-eval-run1-no-write-permission.txt, evidence/live-eval-run2-acceptEdits.txt |
| EVAL-005 | AC-FR-016, AC-FR-017, AC-FR-018 | pass | evidence/waivers-and-close.txt |
| EVAL-006 | AC-FR-001, AC-FR-005 | pass | evidence/c-locale-check-and-gate.txt |
| EVAL-007 | AC-FR-021 | pass, with a gap in the docs (EVAL-F1, EVAL-F5) and one file unread | none (read against code) |
| EVAL-008 | AC-FR-006 | pass (negative side only) | evidence/c-locale-check-and-gate.txt |
| EVAL-009 | AC-FR-002, AC-FR-003, AC-FR-004, AC-FR-012, AC-FR-013 | blocked, not exercised here | none; covered by 06-verification |

## Failures
- EVAL-004 run 1 FAILED. `soft-foundry eval --live --shell claude --case review-finds-planted-defect` with no shell arguments: the fresh review session identified the planted defect and a test gap (REV-001 refund not capped, REV-002 negative not zeroed, REV-003 empty test file) but its writes into 13-review were refused because a non-interactive claude -p session cannot answer permission prompts, so no findings were recorded and the case failed ("0 findings recorded", exit 2). This is the eval's result for AC-FR-015 on a default invocation, and it is not a miss by the reviewer.
- EVAL-004 run 2, same case with `-- --allowedTools "Read Write Edit Glob Grep Bash" --permission-mode acceptEdits`: PASS, the session recorded REV-001, REV-002 and REV-003 matching the pattern (shell claude, anthropic/claude-sonnet-5-5, exit 0).

## Observations
- EVAL-F2 (minor): the Rails profile records the testing entry `ruby`, not an rspec-named entry; the specification (REQ-FR-008) speaks of "rspec-style testing". The shipped test asserts `ruby`, so test and behaviour agree; the wording differs.
- EVAL-F1 (minor): the README says a live session runs with the host's own permission mode but does not say that an unattended claude session needs shell arguments after `--` to be allowed to write the phase directory, so the default `eval --live --shell claude` fails as in run 1 unless the maintainer grants it. Either document it or have the live runner pass the same arguments `phase run` uses.
- This skill is denied the harness-evals directory, so that directory's README could not be read and AC-FR-021 is not judged for it.
- doctor in the fresh Rails repository prints a fail for the guard hook not being installed (claude and codex not installed) together with mode: block from the repository policy; the mode and source are shown as required.
- AC-FR-013, AC-FR-012, AC-FR-002 to 004 and the positive side of AC-FR-006 need planted defects or fake shells; they are not user journeys and rest on the verification suite.

- EVAL-F4 (cosmetic): when the guard refuses a call it could not decide, the message reads "the  skill's permissions.yml" with an empty skill name (seen on the tilde-user and NUL-byte routes). The refusal itself is correct (exit 2).
- EVAL-F5 (minor, already owed in 09-remediation): the README guard paragraph does not yet describe the Grep and Glob matcher, the cd/glob/symlink/brace handling, or that existing repositories rerun `hooks install`. This repository's own .claude/settings.json predates the matcher (a skill cannot write it).

## Accessibility observations
Command-line output only. Outcome words (pass, fail, skip, error, warn) lead each line after the status glyph; the text is readable with glyphs and color removed; JSON carries the same facts; no prompts; next steps are named in errors. Keyboard-only: nothing needs a pointer. No screen reader was run.
