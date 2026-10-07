# Functional Review

## Scope reviewed

Independent reading of the session ledger (`lib/soft_foundry/session_ledger.rb`), the CLI commands (`session`, `sessions`, `resume`, `hooks install|uninstall --sessions`, the doctor line, `phase run`), the user-level installer (`lib/soft_foundry/hooks.rb`), Grok's tool names in `lib/soft_foundry/guard.rb`, session IDs in `lib/soft_foundry/phase_runner.rb`, and `recorded_sessions` in `lib/soft_foundry/snapshot.rb` and `lib/soft_foundry/ui/assets/app.js`. Compared with REQ-SL-001 through REQ-SL-015 and AC-001 through AC-015.

Evidence used, not re-run: verification at `93acd89` (466 runs, 0 failures; RED commits `d278ecf` and `88eee99`), evaluation journeys EVAL-001 through EVAL-008, attack cases ATTACK-001 through ATTACK-008. `git diff 93acd89..HEAD` has no changes under `lib/`, `test/`, `exe/`, `README.md`, or `.ai/`. This review also ran `soft-foundry session`, `soft-foundry session foo`, and `soft-foundry phase` against this checkout.

## Findings

| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-FUN-001 | minor | `lib/soft_foundry/cli.rb` `session_log` | Any `soft-foundry session` invocation other than `session log` exits 0 and prints nothing. Confirmed: `session` and `session foo` both exit 0 with empty stdout and stderr. REQ-SL-005 requires that silence only for the hook command. A person who mistypes the subcommand is told they succeeded. | `.ai/rules/errors.md` (user-facing errors name what went wrong and what to do next); `.ai/rules/general.md` (do not convert a failure into apparent success). REQ-SL-005 authorizes the silent exit only for `session log`. |
| REV-FUN-002 | minor | `lib/soft_foundry/cli.rb` `phase` | The error text for `phase` and `phase run` still says `--shell claude\|codex`. Help text and `PhaseRunner::SHELLS` include `grok`, and EVAL-008 ran `phase run --shell grok` successfully. Confirmed: `soft-foundry phase` prints the usage line without `grok` and exits 1. | REQ-SL-011 (Grok is a shell the runner launches). `.ai/rules/errors.md`. |

## What conforms

- **REQ-SL-001 / AC-001.** `write` and `search_replace` are write tools (`file_path`), `read_file` is a read (`target_file`), `run_terminal_command` is a shell (`command`). Same decisions as Claude Code's Write, Read, and Bash. An unknown name stays "not guarded" (residual TM-001, below).
- **REQ-SL-002 / REQ-SL-003 / AC-002 / AC-003.** One entry per agent and session ID; `first_at` and `first_prompt` are kept; later prompts update `latest_prompt`, cwd, place, and `last_at`. Repository root, branch, change slug, and `current_phase` come from the folder. Outside a repository the place fields are empty and the entry is still written. A line that does not parse is kept verbatim.
- **REQ-SL-006 / AC-007.** `hookEventName` forces agent `grok` regardless of `--shell`. EVAL-003 saw one Grok row with both hook files installed.
- **REQ-SL-007 / AC-008.** `sessions` matches every word, case-insensitive, across prompts, folder, branch, and change (the repository path is also searched, which is slightly wider than the requirement and not a miss). Filters are exact. Newest `last_at` first. `--json` is the same rows plus `status` and `resume`. Empty output says `none found` and how to install the hook.
- **REQ-SL-008 / AC-009.** `resume` prints one command and starts nothing. No match exits 1 and names `soft-foundry sessions --change …`. It does not repeat the status word; that gap is REV-A11Y-002.
- **REQ-SL-010 / AC-011.** Install writes one marker-scoped `UserPromptSubmit` entry per agent file, is idempotent, leaves other keys and hooks, skips a foreign find-session skill, refuses a symlink, prints the Codex `/hooks` trust step, and uninstall removes only its own entries. Doctor's session line does not change the exit code. EVAL-001 did this against a copy of a real home directory.
- **REQ-SL-011 / AC-012.** Claude gets `--session-id` and `--name`. Grok gets `-s <id> … -p <prompt>` (the prompt is the value of `-p`, after REM-001). Codex gets no preset id; `executed_by.session_id` is the newest Codex ledger row for this repository whose `first_at` is at or after the run's `started_at`, or null. `cwd` is the repository root. EVAL-008 ran the Grok argv live and the ledger row matched `executed_by.session_id`.
- **REQ-SL-012 / AC-013.** The change page gets `recorded_sessions` for this repository and slug, labelled "Recorded sessions", separate from open shells. The evaluation screenshot shows that section.
- **REQ-SL-014 / AC-014.** CHECK-007: 0.197 to 0.217 seconds per prompt on a 5,000-entry ledger. The ledger is not pruned, as the specification says.
- **REQ-SL-015 / AC-015.** README "Finding and resuming sessions", help text, and `.ai/schemas.md` `executed_by.session_id` and `cwd` describe the store, the commands, install and removal, Grok coverage, the 1 MB skip, and the control-character folder case.

Two test corrections after the first RED commit are accepted. The fixture directory name `sf-ledger` made every row match a search for "ledger"; renaming it to `sf-state` fixes the fixture, not the expectation. The doctor test now allows a leading `warn` word, which is the status word the session-hook line is specified to use, and still requires every line to lead with `pass`, `fail`, or `warn`.

## Conformance

Conforms with advisories. The acceptance criteria hold in the code and in the bound evidence. REV-FUN-001 and REV-FUN-002 are small command-surface gaps, not failed criteria. REV-A11Y-002 (resume omits the status word) is recorded on the accessibility review.
