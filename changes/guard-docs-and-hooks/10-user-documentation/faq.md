# FAQ Candidates

Each entry cites the EVAL IDs that demonstrate the answer. Journeys are this record's (`07-evaluation/journeys.yml`) unless prefixed `factory-readiness`.

## Q: My repository has had the guard hook for a while. Why are Grep and Glob not checked, and why was a change to `.ai/policies/enforcement.yml` during a shell command not restored?
A: The hook was installed before 0.21.0: its `PreToolUse` matcher has no `Grep` or `Glob` and there is no `PostToolUse` entry. Run `soft-foundry hooks install --claude` again. The rerun replaces the matcher with `Edit|Write|MultiEdit|NotebookEdit|Read|Grep|Glob|Bash`, adds the `PostToolUse` entry running `guard --after`, keeps every other hook and key in the file, and changes nothing on a second run. `doctor` reports `installed` either way, because it checks presence, not the matcher.
Evidence: EVAL-003, EVAL-002

## Q: I wrote `mode: off` in `.soft-foundry/enforcement.yml` and the guard still blocks. Why?
A: YAML reads a bare `off` as the boolean false, which is not a mode, so the file is ignored and the repository policy applies. Write it quoted, `mode: "off"`, or set `SOFT_FOUNDRY_GUARD=off`, which needs no quoting and wins over both files. `doctor` names the source in effect.
Evidence: EVAL-005, EVAL-004

## Q: The guard refused `cd /tmp 2>/dev/null && ls` with "could not be decided (NoMethodError ...)". Is that a bypass?
A: No. The guard fails closed, so a command it cannot decide is refused. Today a `cd` or `pushd` that leaves the repository followed by another token in the same segment, typically a redirection, hits this. `cd /tmp && ls`, `cd /tmp; ls` and `cd lib 2>/dev/null && ls` are decided. The defect is recorded for a later change.
Evidence: EVAL-004 (`glob-outside.txt`), EVAL-F-002

## Q: Why was `cat .claude/settings.json` (or `tail .soft-foundry/guard.log`) refused when the Read tool reads the same file?
A: The guard's own configuration, meaning `.ai/policies/enforcement.yml`, everything under `.soft-foundry/`, and the hook entries in `.claude/settings.json`, `.claude/settings.local.json` and `.codex/hooks.json`, may not be named in a shell command by any skill, because the guard cannot know what a command does to it. Read is checked against deny_read only, so the Read tool is allowed.
Evidence: EVAL-001, EVAL-004

## Q: How do I check that the guard is installed and which mode is in effect?
A: Run `soft-foundry doctor`. The guard line reads `pass guard hook (claude: installed, codex: installed; mode: block, repository policy (.ai/policies/enforcement.yml))`, with `not installed` for a host without the entry and, when neither has one, `fail` plus the install command. The source is `repository policy`, `machine-local override (.soft-foundry/enforcement.yml)`, or `SOFT_FOUNDRY_GUARD environment variable`.
Evidence: EVAL-002, EVAL-003, EVAL-004

## Q: I edited the guard's configuration in my own shell and the next command restored it, reporting tamper. Why?
A: A shell command was interrupted before its post-call check, leaving a baseline in `.soft-foundry/guard-baseline.yml`. One older than thirty minutes is refreshed at the next shell call, but inside that window a hand edit is read as a change during a call. Run `soft-foundry guard --after` once before editing: it consumes the baseline and prints nothing when nothing changed. `hooks install` and `hooks uninstall` clear the baseline too. An edit made between two commands with no baseline pending stands.
Evidence: EVAL-004 (baseline consumed by the check; quiet with nothing to restore; a forty-minute-old baseline refreshed; `hooks install` clears it), EVAL-003; factory-readiness EVAL-F7 (closed) for the thirty-minute rule

## Q: `soft-foundry eval --live --shell claude` fails with "0 findings recorded". Did the review miss the defect?
A: No. The unattended Claude Code session found it but could not write the phase directory. Pass the shell's own flags after `--`: `soft-foundry eval --live --shell claude --case review-finds-planted-defect -- --allowedTools "Read Write Edit Glob Grep Bash" --permission-mode acceptEdits`.
Evidence: factory-readiness EVAL-004 (run 1 fail, run 2 pass)

## Q: Does Codex get the post-call restore?
A: No. `hooks install --codex` writes a `PreToolUse` entry only (matcher `Bash|apply_patch|Edit|Write`). The restore is installed for Claude Code and for Grok, which runs the Claude Code entry from `.claude/settings.json`.
Evidence: EVAL-002 (`hooks-match.txt`), EVAL-003

## Q: An Edit failed with "String to replace not found" and there is no guard line for it. Did the guard miss it?
A: No. Claude Code validates an Edit's input before it runs `PreToolUse` hooks, so an Edit that cannot apply never reaches the guard and nothing is written. A write that can apply is shown to the guard and refused when the skill may not write there.
Evidence: EVAL-001, EVAL-F-006

## Q: A shell command naming `.ai/policies/anti-fudging.yml` was refused, but that file does not exist. Why?
A: Protected policy and harness material (`.ai/policies/`, `.ai/harness-evals/`) are refused by name in a shell command, whether or not the file exists.
Evidence: EVAL-001 (item 2)

## Q: What does a refusal tell me, and where is it recorded?
A: Every refusal names the tool, the path, the skill, the mode, and where the override is documented, and is one line in the machine-local `.soft-foundry/guard.log`, such as `2026-11-06T12:41:45Z block Grep skill=evaluation paths=.ai/harness-evals searches inside evaluation's deny_read set`. In warn mode the line starts `! warn guard:` and the call runs. Read the log with the Read tool, not from the shell.
Evidence: EVAL-001, EVAL-004, EVAL-009

## Q: Is anything guarded on `main`, or after a change is closed?
A: No. The guard resolves the active skill from the branch's change record and its `current_phase`; outside a change branch, or once the change is closed, every call is allowed.
Evidence: EVAL-004
