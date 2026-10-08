# Implementation Log

## Changes made
1. RED `d278ecf`: `test/session_ledger_test.rb` (capture, masking, modes, control characters, Grok detection, ID validation, quoting, status words, 20-process concurrency, corrupt line, symlink, silent hook, 5,000-entry timing, lookup, resume), `test/session_hooks_test.rb` (user-level install, idempotence, fail-open command, uninstall, foreign skill left alone, symlink refusal, doctor), Grok cases in `test/guard_test.rb`, session IDs and the Codex ledger lookup in `test/phase_runner_test.rb`, the Grok runner test rewritten in `test/cross_cli_hooks_test.rb`, recorded sessions in `test/snapshot_test.rb` and `test/ui_assets_test.rb`. 14 failures and 18 errors at RED.
2. GREEN `98b55d1`:
   - `lib/soft_foundry/guard.rb`: `write`, `search_replace` as writes; `read_file` as a read with the path from `target_file`; `run_terminal_command` as shell.
   - `lib/soft_foundry/session_ledger.rb` (new): `record` (agent detection, ID check, repository/branch/change/phase lookup, masking, control-character removal, upsert under a sibling lock file, atomic rename, 0700/0600, symlink refusal), `entries`, `search`, `latest`, `resume_command`, `status`, `default_path`.
   - `lib/soft_foundry/hooks.rb`: `install_sessions`, `uninstall_sessions`, `sessions_installed`, the hook command (marker `soft-foundry:sessions`, fail-open, output discarded, 10-second timeout), and the find-session skill text.
   - `lib/soft_foundry/cli.rb`: `session log` dispatched before anything that can print; `sessions`; `resume`; `hooks install|uninstall --sessions`; a `doctor` line that never changes the exit code; Grok's guard warning in `phase run`; the Codex session lookup after a run; help text.
   - `lib/soft_foundry/phase_runner.rb`: `Launch#session_id`, `--session-id`/`--name` for Claude Code, `-s` for Grok, `executed_by.session_id`/`cwd`, `recorded_session`, Grok in `HOOKED_SHELLS`.
   - `lib/soft_foundry/snapshot.rb` and `ui/assets/app.js`: `recorded_sessions` on a change and a "Recorded sessions" section.
   - `lib/soft_foundry/processes.rb`: the three new commands are recognized by `ps`.
   - `README.md` ("Finding and resuming sessions", guard and runner sections), `.ai/schemas.md` and `.ai/templates/handoff.yml` (`executed_by` fields), version 0.18.0.
3. Full suite 466 runs, 0 failures, with `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, and `SOFT_FOUNDRY_BILLING` unset; `check` passes; `scan` shows only the five pre-existing warnings in older records.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
None substantive. Two RED tests were wrong and are recorded as deviations.
