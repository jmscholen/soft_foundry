# Test Plan

Minitest, new test files only (REQ-023 forbids editing existing expectations). Sessions are stood in for by the existing `@runner` seam (a lambda taking a launch) for logic tests, and by stub `claude` scripts on a temp `PATH` for the tests that need real processes (signals, timing, `ps`, environment). No network; provider keys unset when running the suite. Fixtures reuse the helpers the existing `phase_runner_test.rb` and `lifecycle_tracks_test.rb` use to build a temp repo with `.ai/` and a change record.

## Unit
- `test/record_lock_test.rb`: acquire/release; second process holding the flock makes the call fail in about 10 s naming the lock (shortened timeout injected); symlinked lock path refused; reentrancy; lock freed when the holder is killed.
- `test/change_record_update_test.rb`: `update_metadata` re-reads disk (a write by another handle between load and update is not lost); `transaction` leaves everything unchanged when a staged write is made to fail; every YAML parses afterwards.
- `test/control_plane_downstream_test.rb`: `downstream(verify)`, `downstream(remediate)` (follows the remediate-to-verify transition), `downstream(judge)` empty, fixed-point termination; `isolated_phases` accessor; absent key gives `[]`.
- `test/text_free_text_test.rb`: empty, 500 vs 501 characters, newline, ESC, NUL, tab, `: `, `---` (allowed but stored inert), unicode.
- `test/phase_reopen_test.rb`: reset set and untouched pending phases (byte-identical), evidence files byte-identical, history entry shape and `previous`, `current_phase`, `judged -> in_progress`, intake unchanged, refusals (unknown phase, bad reason, closed/released/exploring/awaiting_human, nothing to reset, marker present) each writing nothing, reopening specify.
- `test/guard_session_marker_test.rb`: marker resolves the skill; unknown, empty, mixed-case, `../x`, non-isolated-in-parallel each a violation under warn and block modes; no marker equals today.
- `test/check_isolated_phases_test.rb`: shipped list passes; implement/review/judge/unknown/code-writing skill fails naming the id.
- `test/release_state_test.rb`: release preconditions, item validation, carry-over under own ids, discharge, close gating, `merged_unclosed?` truth table, release-block lint.

## Integration
- `test/cli_phase_reopen_test.rb`: through `Cli`, exit codes, output lines and prefixes, no ANSI, nothing read from stdin, error text names the next step.
- `test/phase_run_auto_reopen_test.rb`: stale complete phase auto-reopens and runs (stub runner), current phase refused with no byte change, closed/released/predecessor-incomplete refused with no reset, `--dry-run` writes nothing.
- `test/phase_run_parallel_test.rb`: both phases concurrent (stub sessions that sleep and record start/end times), refusals start nothing (non-isolated, duplicate, mixed case, one phase, predecessor), env expansion per phase and name validation, warn without `--env`, secret never in files/stdout/stderr/`ps`, one session failing, missing shell, shared `commit_sha`, no runner commit, committing stub triggers warn plus non-zero, SIGINT reaches every child, interleaved `begin!/finish!` from two processes leaves parseable YAML with no lost update, `current_phase` after the run, wall-clock under 3 s, reopen under 1 s on a full lifecycle record.
- `test/cli_change_release_test.rb`: release/discharge/close sequences, refusals, marker refusals, carried judgment items, `ci` on a merged fixture branch (released with open, all discharged, malformed, neither).
- `test/released_consumers_test.rb`: `gate`/`ci` do not evaluate staleness, `scope` claims nothing, `snapshot` summary/board/timeline, `ps` table, `learn promote`, guard/runner/`phase run`/`phase reopen`/`change reopen` refusals, harness-eval planting.
- `test/ui_released_test.rb`: server JSON carries status and count; `app.js` text includes "released" and the count, items in a table with headers, a `<script>` description appears as text (reading the asset and the rendered DOM builder).
- `test/phase_lifecycle_docs_test.rb`: `workflow.yml`, metadata template, `schemas.md`, `.ai/README.md`, `README.md`, `docs/user/`, usage text, and the `ps` table all name the commands and the new keys (AC-050).
- Harness evals (run by `soft-foundry eval`, not the suite): gate case planting a malformed release block, gate case planting a non-isolated parallel request, live case for stale auto-reopen. Live cases need real coding shells and are run by hand at verification.
- Regression: the whole existing suite, unedited, passes (AC-051).

## Acceptance criteria coverage
| Criterion | Test layer | Planned test |
| --- | --- | --- |
| AC-001, AC-002, AC-003 | integration | `cli_phase_reopen_test.rb` (mid-lifecycle, remediate transition, pending skipped) |
| AC-004 | unit | `phase_reopen_test.rb` (evidence bytes identical, handoff fields cleared) |
| AC-005, AC-006 | unit + integration | `phase_reopen_test.rb` history shape; `change reopen`/exploring `reopenings` untouched |
| AC-007, AC-008, AC-009 | integration | `phase_run_auto_reopen_test.rb` |
| AC-010 | unit | `phase_reopen_test.rb` (`judged`, intake) |
| AC-011, AC-012 | integration | `cli_phase_reopen_test.rb` refusal matrix, no file changes |
| AC-013, AC-014 | integration | `cli_phase_reopen_test.rb` marker refusal; auto-reopen before launch; gate fails on pending phase |
| AC-015 | integration | `cli_phase_reopen_test.rb` reopen specify then `change close` refused |
| AC-016, AC-017 | unit + integration | `phase_reopen_test.rb` nothing to reset; `change_record_update_test.rb` injected staging failure |
| AC-018 | unit | `check_isolated_phases_test.rb` |
| AC-019, AC-020, AC-021 | integration | `phase_run_parallel_test.rb` |
| AC-022, AC-023, AC-024 | integration | `phase_run_parallel_test.rb` (env expansion, warn, secret scan incl. `ps`) |
| AC-025, AC-026, AC-027 | unit | `guard_session_marker_test.rb`; existing guard/panel tests run unedited |
| AC-028, AC-029, AC-030 | unit + integration | `record_lock_test.rb`, `change_record_update_test.rb`, `phase_run_parallel_test.rb` |
| AC-031, AC-032, AC-033 | integration | `phase_run_parallel_test.rb` (failure isolation, shared HEAD, committing stub, SIGINT) |
| AC-034 | integration | `phase_run_parallel_test.rb` timing |
| AC-035, AC-036, AC-037, AC-038 | unit + integration | `release_state_test.rb`, `cli_change_release_test.rb` |
| AC-039, AC-040, AC-041 | integration | `cli_change_release_test.rb` (`ci` on a merged fixture) and `release_state_test.rb` lint |
| AC-042, AC-043 | integration | `cli_change_release_test.rb`; existing `cli_change_close_test.rb` unedited |
| AC-044 | integration | `released_consumers_test.rb` |
| AC-045 | integration | `released_consumers_test.rb` (STATUSES) plus the harness gate cases |
| AC-046, AC-047 | integration | output assertions in `cli_phase_reopen_test.rb`, `phase_run_parallel_test.rb`, `cli_change_release_test.rb` |
| AC-048 | integration | `ui_released_test.rb` |
| AC-049 | integration | `released_consumers_test.rb` (snapshot timeline) |
| AC-050 | integration | `phase_lifecycle_docs_test.rb`, `soft-foundry check` |
| AC-051 | regression | full existing suite, no edits |

## Not covered and why
- Real coding shells (`claude`, `codex`, `grok`) in a parallel run: stubs stand in; the live harness case and the hand run at verification cover one real session. Guard behaviour inside a real hook is covered by the existing cross-CLI hook tests plus the new marker unit tests.
- The `env -u` marker bypass (THREAT-002): not preventable by the tool; test asserts the documented behaviour (refusal only when marker present) and the attack phase reports the residual.
- Crash between the two `rename` calls of a `transaction`: window is a single syscall; covered by staging-failure injection only.
- UI contrast numbers (1.4.3/1.4.11): reused existing tokens; checked by the accessibility review rather than a unit test.
