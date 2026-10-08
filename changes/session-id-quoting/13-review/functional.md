# Functional Review

## Scope reviewed

Requirements in `00-intake/request.md` (REQ-SQ-001, REQ-SQ-002, REQ-SQ-003). The specification phase was skipped; those three IDs are the acceptance bar. Code reviewed at `d08f74e79af9408d0d34524b803ffc57ae279911`, whose `lib/` and `test/` trees match the implementation commit `6f753070e06ed9eb74b9744541b409429f81afa8`.

Behavior checked in `SessionLedger.trusted?`, `SessionLedger#entries`, `SessionLedger.resume_command`, `CLI#sessions`, `CLI#resume`, `Snapshot#recorded_sessions`, and `PhaseRunner#recorded_session`. `test/session_id_quoting_test.rb` was re-run here (2 runs, 0 failures). The full suite was not re-run; verification's log at the implementation commit reports 468 runs and 0 failures, and no library or test file has changed since that commit.

## Findings

None.

## Deviations

`05-implementation/deviations.md` asks review to approve a correction, made in the same commit as the fix, to the RED test's quoting expectation.

Approved. At `af7da27` the expectation is a double-quoted Ruby string. Evaluated, that string is `claude --resume x;\ touch\ PWNED`: the backslash before the semicolon is not kept, and the backslashes before the spaces are. That matches neither the old interpolation (`x; touch PWNED` with the id pasted raw) nor `Shellwords.escape` (`x\;\ touch\ PWNED`). The replacement, a single-quoted literal of the escaped form, is the real `Shellwords` result. The old interpolation does not end with it, so the corrected test would still have failed before the fix. REQ-SQ-002 did not change. This is not a weakened expectation under `.ai/rules/testing.md`.

## Requirement results

**REQ-SQ-001.** `entries` is the only read of the ledger that lookup uses. `search` and `latest` call it. `sessions` (text and `--json`) and `resume` call `search` or `latest`. `Snapshot#recorded_sessions` calls `search`. `PhaseRunner#recorded_session` calls `search`. A line is kept only when `trusted?` is true: `session_id` is a String matching `SessionLedger::ID`, `agent` is `claude`, `codex`, or `grok`, and `cwd` is a String. Probed and rejected: shell metacharacters in the id, a newline in the id, a numeric id, an agent outside those three, a missing or non-string `cwd`, and a missing agent. The new test covers `search`, `sessions`, `sessions --json`, `resume` of a change that exists only on planted lines (exit 1, empty stdout), and the line count of the file. Attack case ATTACK-001 reports the same refusal. Lines that fail the check are not deleted by lookup; the test's line count is the planted lines plus the one real session.

A later `record` still rewrites every parseable line through `JSON.generate`, trusted or not. That is the pre-existing `update` path, not a delete. Unparseable lines stay raw strings. The intake's "untouched" requirement is met for the filter itself: lookup does not rewrite the file.

**REQ-SQ-002.** `resume_command` passes the session id through `Shellwords.escape` as well as the folder. Callers in the CLI and the snapshot all use that method, and the page sets the resulting string with `textContent` (`el`, `text:`). For `x; touch PWNED` the command ends in `x\;\ touch\ PWNED`. Command substitution, a backtick, and a single quote are backslash-escaped. A newline is quoted with the stdlib line-break form and is not returned by lookup, because it fails `ID`. A plain id such as `0199-abc` or `good-1` is unchanged, which is what EVAL-001 recorded for a real Grok session. ATTACK-002 ran the semicolon payload through a stub `claude` and observed one argument and no extra file.

**REQ-SQ-003.** `SoftFoundry::VERSION` is `0.18.1`. `soft_foundry.gemspec` reads that constant.

When every line fails `trusted?`, `sessions` prints `sessions: none found` and `sessions: 0 recorded in <path>`, because the count is `entries.size`. EVAL-OBS-001 notes that this can be read as an empty ledger. The missing-file sentence is a different line (`no ledger at <path> yet`). The intake chose skip-with-no-warning over printing anything from the rejected line. The count matches that decision.

## Conformance

Conforms. REQ-SQ-001, REQ-SQ-002, and REQ-SQ-003 hold. The test-oracle correction is approved above. No blocking finding.
