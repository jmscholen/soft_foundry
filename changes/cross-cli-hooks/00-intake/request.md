# Change Intake

## User intent
After the five ECC-inspired additions, the maintainer asked whether they work with any LLM CLI, such as Grok or Codex. The honest answer was: three never touch a CLI; the phase runner knew Claude Code and Codex; the guard's decision is host-neutral but its install step wrote only Claude Code's settings and its payload reading assumed Claude Code's field names. The maintainer said "add both": Grok in the runner, and a Codex hook install with whatever adapter Codex's contract needs, checked against a real install rather than written from memory.

What was checked: Codex 0.139.0 and Grok 1.0.30 are installed here. Codex's published hook documentation states that project hooks live in `.codex/hooks.json` (or `[hooks]` in `config.toml`) in the same shape as Claude Code's settings, that `PreToolUse` delivers `tool_name` and `tool_input` on stdin, that exit 2 refuses, that its shell tool is `Bash` with `tool_input.command` as a string or array, that file edits arrive as `apply_patch` (also matched by the `Edit` and `Write` aliases) with the patch text in the command, and that a non-managed hook runs only after the person reviews and trusts it with `/hooks`. Grok's headless form is `grok -p <prompt>` (`--single`), and its help mentions no hook mechanism.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-XCLI-001.** The guard treats `tool_name` `apply_patch`, and `Edit`/`Write` calls whose `tool_input` has no file path but has a `command`, as file writes: every path an apply_patch header adds, updates, deletes, or moves to (`*** Add File:`, `*** Update File:`, `*** Delete File:`, `*** Move to:`) is checked against the skill's write and deny_write sets, and any path outside the repository is refused. Text that is not a patch is allowed as "no file path in the tool call".
- **REQ-XCLI-002.** A `tool_input.command` given as an array (Codex's form) is joined into text before the Bash path heuristic or the patch parser reads it.
- **REQ-XCLI-003.** `soft-foundry hooks install --codex` writes the guard entry into `.codex/hooks.json` with matcher `Bash|apply_patch|Edit|Write`, keeping every other key and hook, idempotently by the marker in the command; it prints that Codex runs a project hook only after the person reviews and trusts it with `/hooks`. `hooks uninstall --codex` removes only that entry. `--local` with `--codex` is refused with the reason. Both flags may be given together.
- **REQ-XCLI-004.** `doctor` prints one `guard hook` line that passes when either host has the hook, naming both hosts' states, the mode, and its source, and the install commands when neither has it.
- **REQ-XCLI-005.** `phase run --shell grok` launches `grok -p [extra...] <prompt>` and prints a `! warn guard:` line saying grok has no hook mechanism so the skill's permissions are policy only for the session. `--shell codex` warns when the Codex hook is not installed, naming `hooks install --codex`, and is silent once it is; the Claude warning names `--claude`.
- **REQ-XCLI-006.** `README.md` (guard and runner sections), `AGENTS.md`, and the help text document the Codex install and trust step, the apply_patch handling, and Grok's policy-only status. The Codex hook is installed in this repository's `.codex/hooks.json`. Version 0.15.0.
- **REQ-XCLI-007.** The two instincts at or above the threshold from control-plane-scan are promoted into `.ai/rules/learned.md` through this record.

## Constraints
- The guard's decision logic stays host-neutral; only the payload reading widens.
- A patch that cannot be parsed is a pass-through with a reason, never a refusal of something unrelated.
- Every new line carries its outcome as a word per `.ai/rules/accessibility.md`.
- Codex's trust step is a fact about Codex, stated at install time and in the README, not worked around.

## Non-goals
- A Grok hook adapter. Grok has no hook surface to adapt to; if one appears, it is one entry in the runner's hooked-shells list and one installer.
- Codex's `config.toml` inline `[hooks]` form. `hooks.json` is the documented project-scope file and the one written.
- Running a live Codex or Grok session through the runner in this change.

## Task classification
Feature: a patch parser and array handling in the guard, a Codex installer and uninstaller, a combined doctor line, Grok in the runner with per-shell warnings, documentation, tests, this change's RED commit and learning phase, and an instinct promotion.

## Initial risk
low. The guard widens what it can read; the installer writes one more JSON file through the same safe path; the runner gains one shell entry. Existing tests and change records pass unchanged.
