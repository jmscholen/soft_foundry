# Evaluation Results

Re-run at HEAD 1b49874 after remediation REM-004 (the guard records its own configuration before each tool call and restores and refuses any change to it after a shell command; `hooks install --claude` wires the PostToolUse check; an undecidable refusal no longer prints an empty skill name). The earlier evaluation was bound to 9307b23 and went stale. Every journey below was run again in fresh scratch repositories under the session scratchpad, except where stated.

Commit SHA: 1b49874309152d74533590922752ba9faed6668c

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | AC-FR-019, AC-FR-020 | pass (init, check, profile rails/ruby, change new sets accessibility, eval 12 pass 0 fail 1 skip, JSON version 1) | evidence/rails-install-profile-change-new-eval.txt |
| EVAL-002 | AC-FR-007, AC-FR-008, AC-FR-019 | pass (5 calls allowed, 13 refused as expected incl. chained cd .., brace, unresolvable tilde, NUL byte, Grep and Glob on harness-evals; warn override exits 0) | evidence/rails-guard-decisions.txt |
| EVAL-003 | AC-FR-009, AC-FR-010, AC-FR-011, AC-FR-014 (partly), AC-FR-020 | pass for what was run (unknown case, live case without --live, --live without --shell, unsupported shell); planted-case parts not re-run | evidence/eval-live-refusals.txt |
| EVAL-004 | AC-FR-015 | pass on the second run, fail on the first | evidence/live-eval-run1-no-write-permission.txt, evidence/live-eval-run2-acceptEdits.txt |
| EVAL-005 | AC-FR-016, AC-FR-017, AC-FR-018 | pass | evidence/waivers-and-close.txt |
| EVAL-006 | AC-FR-001, AC-FR-005 | pass | evidence/c-locale-check-and-gate.txt |
| EVAL-007 | AC-FR-021 | pass for behaviour; documentation gap (EVAL-F1, EVAL-F5); one file unread | none (read against code) |
| EVAL-008 | AC-FR-006 | pass (negative side only) | evidence/c-locale-check-and-gate.txt |
| EVAL-009 | AC-FR-002, AC-FR-003, AC-FR-004, AC-FR-012, AC-FR-013 | blocked, not exercised here | none; covered by 06-verification |
| EVAL-010 | AC-FR-007, AC-FR-008 (REM-004 post-call check) | pass | evidence/guard-post-call-restore.txt |

## Failures
- EVAL-004 run 1 FAILED. `soft-foundry eval --live --shell claude --case review-finds-planted-defect` with no shell arguments: the fresh review session found the planted defect (REV-001 refund not capped, REV-002 negative not zeroed, REV-003 empty test file) but every write into 13-review was refused (non-interactive session, no permission granted), so no findings were recorded: "0 findings recorded", exit 2. This is the eval's real result on a default invocation, not a reviewer miss.
- EVAL-004 run 2, same case with `-- --allowedTools "Read Write Edit Glob Grep Bash" --permission-mode acceptEdits`: PASS (claude, anthropic/claude-sonnet-5-5, findings REV-001, REV-002, REV-005 matched; exit 0).

## Observations
- EVAL-F1 (minor, unchanged): an unattended live eval on claude needs shell arguments after `--` to be allowed to write the phase directory; the documentation does not say so and the default invocation fails. Document it or pass the arguments `phase run` uses.
- EVAL-F2 (minor, unchanged): the Rails profile records the testing entry `ruby`, not an rspec-named entry; REQ-FR-008 says "rspec-style testing".
- EVAL-F4 is CLOSED at this commit: the undecidable refusals (unresolvable tilde user, NUL byte) now read "the guard refuses what it cannot decide"; exit 2 unchanged.
- EVAL-F5 (minor, widened): a search of README.md finds nothing on the Grep/Glob matcher, the cd/glob/symlink/brace handling, the PostToolUse post-call check (`guard --after`, the baseline file, the tamper log line), or that an existing repository reruns `hooks install --claude`. This repository's own .claude/settings.json has no PostToolUse entry (a skill cannot write it).
- EVAL-F6 (minor): the planted-case journeys (reversed expectation, malformed YAML, unknown check, oversize case) were not re-run at this commit; they need the case-file format and the harness-evals directory, which this skill is denied. The eval code is unchanged since 9307b23, where they passed; verification at HEAD owns them.
- EVAL-F3 (minor): AC-FR-002, 003, 004, 012, 013 and the positive side of AC-FR-006 are not user journeys here; the harness-evals README is unread, so that part of AC-FR-021 is unjudged.
- EVAL-010 shows the corrective control works for the path it is meant to cover: a change to the policy, or a new machine-local override, made during a call is restored and refused (exit 2) with a tamper line in the guard log, and an edit between calls stands. It was exercised with a direct edit standing in for any spelling the preventive check misses; whether every spelling is covered is the attack phase's question. Codex has no PostToolUse entry, as REM-004 states.
- doctor in the fresh Rails repository fails the guard-hook line until `hooks install --claude` is run, then passes with mode block from repository policy.
- The scratch intake in EVAL-005 also fails "no placeholders" (placeholder text left unfilled in my scratch request.md); the line under test, waivers permitted, behaves as specified.
- The repository guard refused two of this session's tool calls: one naming the harness-evals README (correct, denied to this skill) and one carrying an unresolvable tilde-user token.

## Accessibility observations
Command-line output only. Outcome words (pass, fail, skip, error, warn) lead each line after the status glyph, readable with glyphs and colour removed; JSON carries the same facts; no command prompted; errors name the next step (the --shell flag, the judge command and --force, the file and its limit, the tamper log and what was restored). Keyboard-only: nothing needs a pointer. No screen reader was run.
