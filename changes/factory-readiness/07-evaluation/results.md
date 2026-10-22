# Evaluation Results

Re-run at HEAD ac3e8cf after remediation REM-006 (only a shell call records the guard baseline; `hooks install` and `hooks uninstall` clear it). The earlier evaluation, bound to 85e9a77, went stale and had found EVAL-F7. Every journey below was run again by hand against the real CLI in a fresh scratch Rails repository under the session scratchpad, except where stated.

Commit SHA: ac3e8cfe995929ce40d334636e750d4625deffe9

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | AC-FR-019, AC-FR-020 | pass (init with LANG unset, check, profile rails/ruby, change new sets accessibility, eval 12 pass 0 fail 1 skip, JSON version 1, doctor guard hook passes) | evidence/rails-install-profile-change-new-eval.txt |
| EVAL-002 | AC-FR-007, AC-FR-008, AC-FR-019 | pass (5 calls allowed, 14 refused as expected incl. chained cd .., brace, unresolvable tilde, NUL byte, Grep and Glob on harness-evals, symlink to the policy, .soft-foundry write; warn override exits 0) | evidence/rails-guard-decisions.txt |
| EVAL-003 | AC-FR-009, AC-FR-010, AC-FR-011, AC-FR-014 (partly), AC-FR-020 | pass for what was run (unknown case, live case without --live, --live without --shell, unsupported shell); planted-case parts not re-run | evidence/eval-live-refusals.txt |
| EVAL-004 | AC-FR-015 | pass on the second run, fail on the first (both re-run at ac3e8cf) | evidence/live-eval-run1-no-write-permission.txt, evidence/live-eval-run2-acceptEdits.txt |
| EVAL-005 | AC-FR-016, AC-FR-017, AC-FR-018 | pass | evidence/waivers-and-close.txt |
| EVAL-006 | AC-FR-001, AC-FR-005 | pass | evidence/c-locale-check-and-gate.txt |
| EVAL-007 | AC-FR-021 | pass for behaviour; documentation gap (EVAL-F1, EVAL-F5); one file unread | none (read against code and README) |
| EVAL-008 | AC-FR-006 | pass (negative side only) | evidence/c-locale-check-and-gate.txt |
| EVAL-009 | AC-FR-002, AC-FR-003, AC-FR-004, AC-FR-012, AC-FR-013 | blocked, not exercised here | none; covered by 06-verification |
| EVAL-010 | AC-FR-007, AC-FR-008 (post-call check) | pass (EVAL-F7 closed: an edit after an Edit/Read/Grep/Glob call stands, hooks uninstall stands, a stale Bash baseline is cleared by hooks install/uninstall; tamper during a Bash call, overlap with another call, and a symlinked settings file are still restored and refused) | evidence/guard-post-call-restore.txt |

## Failures
- No journey failed on behaviour at ac3e8cf.
- EVAL-004 run 1 reports fail, as before: `soft-foundry eval --live --shell claude --case review-finds-planted-defect` with no shell arguments. The fresh review session found the planted defect (REV-001, REV-002, REV-003, REV-005 named in its summary) but could not write into 13-review (non-interactive session, no permission), so "0 findings recorded", exit 2. This is the eval's real result on a default invocation (EVAL-F1), not a reviewer miss.
- EVAL-004 run 2 with `-- --allowedTools "Read Write Edit Glob Grep Bash" --permission-mode acceptEdits`: PASS (claude, anthropic/claude-sonnet-5-5, findings REV-001, REV-002, REV-003, REV-005 matched; exit 0).

## Observations
- EVAL-F7 (major at 85e9a77) is CLOSED at this commit. Scenario A: after an Edit call the maintainer's edit of enforcement.yml (block to warn) stands (guard --after exit 0, mode warn kept). Scenario B: after Read, Grep and Glob calls, `hooks uninstall --claude` stands and doctor reports the hook not installed; a baseline left by an interrupted Bash call is cleared by `hooks install` and `hooks uninstall`. Scenario C (corrected so the edit falls between the completed check and the next pre-call) stands. A tamper in flight during a Bash call, with a Read call overlapping, is still restored and refused (exit 2).
- My first Scenario C attempt put the edit between the pre-call and the check of the same Bash call, which is inside the call; it was correctly restored and refused. The evidence file keeps that attempt and the corrected one.
- In Scenario A the Edit of app/models/user.rb was refused because the scratch change was still at the intake phase (the skill in force there does not write the application); the guard behaved as specified, and the Edit still recorded no baseline, which is what the scenario isolates.
- EVAL-F1 (minor, unchanged): an unattended live eval on claude needs shell arguments after `--` to be allowed to write the phase directory; README.md does not say so (it mentions only the `phase run --shell-arg` form at line 222) and the default invocation fails.
- EVAL-F2 (minor, unchanged): the Rails profile records the testing entry `ruby`, not an rspec-named entry; REQ-FR-008 says "rspec-style testing".
- EVAL-F5 (minor, unchanged): README.md still has no description of the Grep/Glob matcher, the cd/glob/symlink/brace handling, the PostToolUse post-call check (`guard --after`, the baseline file, the young-baseline and shell-only-baseline rules, the tamper log line), or that an existing repository reruns `hooks install --claude`. This repository's own .claude/settings.json has no PostToolUse entry (a skill cannot write it).
- EVAL-F6 (minor): the planted-case journeys (reversed expectation, malformed YAML, unknown check, oversize case) were not re-run at this commit; they need the harness-evals directory, which this skill is denied. The diff from 85e9a77 touches only cli.rb (guard), hooks.rb and tests; eval code is unchanged since 9307b23. Verification at HEAD owns them.
- EVAL-F3 (minor): AC-FR-002, 003, 004, 012, 013 and the positive side of AC-FR-006 are not user journeys here; the harness-evals README is unread, so that part of AC-FR-021 is unjudged.
- Codex has no PostToolUse entry, as REM-004 states; not exercised.
- The scratch intake in EVAL-005/006 fails "no placeholders" (unfilled scratch request.md); the lines under test (waivers permitted, content clean) behave as specified.

## Accessibility observations
Command-line output only. Outcome words (pass, fail, skip, error, warn) lead each line after the status glyph, readable with glyphs and colour removed; JSON carries the same facts; no command prompted; errors name the next step (the --shell flag, the judge command and --force, the tamper log and what was restored, "the guard refuses what it cannot decide"). Keyboard-only: nothing needs a pointer. No screen reader was run.
