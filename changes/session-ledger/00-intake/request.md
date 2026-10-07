# Change Intake

## User intent
The maintainer reviewed an article on agentic engineering (Jacob Bartlett, Jacob's Tech Tavern) and asked how Soft Foundry could improve from it. Five additions were proposed in a shared plan ("Soft Foundry: Agent-Workflow Additions Plan"), and the maintainer asked for them to be built in order. This is the first: never lose a coding session. The article's author keeps a ledger of every agent session (folder, transcript, resume ID) so an agent can find one from a plain-English description and print `cd <folder> && <agent> resume <id>`; the method is published as a gist (https://gist.github.com/jacobsapps/5f3b7501a169085a3def5bb933a7b98d) covering Claude Code and Codex. The maintainer then asked why Grok was left out and to confirm its capabilities; a live check showed Grok 1.0.30 has the hooks this needs, and that Soft Foundry's guard lets Grok's file writes through because it does not know Grok's tool names.

Today `soft-foundry ps` shows only shells that are running, and `phase run` stamps `executed_by` with no session ID or folder, so a finished or interrupted session cannot be found again from Soft Foundry.

## Desired outcome
- **REQ-SL-001 (guard).** The guard recognizes Grok's tool names: `write` and `search_replace` as file writes (path in `tool_input.file_path`), `read_file` as a read (path in `tool_input.target_file`), and `run_terminal_command` as a shell command (`tool_input.command`). A Grok write outside the active skill's write set gets the same decision a Claude `Write` would.
- **REQ-SL-002 (capture).** `soft-foundry session log [--shell claude|codex|grok]` reads one hook payload on stdin and records the session in a machine-local ledger: one entry per agent and session ID, updated in place on later prompts. It never prints, always exits 0, and holds an exclusive lock across the whole read-modify-write. A payload carrying Grok's camelCase `hookEventName` is recorded as Grok whatever `--shell` says, because Grok also runs hooks from Claude's settings files.
- **REQ-SL-003 (entry contents).** Each entry records the agent, session ID, working folder, repository root, branch, the change whose record matches the branch and its current phase (when there is one), the transcript path when the payload gives one, first and last seen times, and the first and latest prompt cut to 140 characters with whitespace collapsed and secret-shaped strings masked.
- **REQ-SL-004 (ledger location).** The ledger is `~/.soft-foundry/sessions.jsonl` (`SOFT_FOUNDRY_SESSIONS` overrides it), outside every repository, with the directory created private to the user and the file readable only by the user.
- **REQ-SL-005 (lookup).** `soft-foundry sessions [TEXT...] [--change SLUG] [--phase PHASE] [--agent NAME] [--limit N] [--json]` lists matching sessions newest first. Each match shows when, which agent, where (repository, branch, change, phase), the first prompt, the exact resume command, and a status word saying whether it is resumable (folder present, and transcript present when one is recorded).
- **REQ-SL-006 (resume).** `soft-foundry resume <change> [phase] [--agent NAME]` prints the one best resume command for that change (newest matching session) and exits non-zero with the reason when there is none. Neither command ever starts a session.
- **REQ-SL-007 (resume command safety).** Resume commands are `cd <folder> && claude --resume <id>`, `codex resume <id>`, or `grok --resume <id>`, with the folder shell-quoted. A session ID that is not a plain identifier is never recorded, so nothing from a payload can inject into a printed command.
- **REQ-SL-008 (install).** `soft-foundry hooks install --sessions` installs the session hook at user level for all three agents (`~/.claude/settings.json`, `~/.codex/hooks.json`, `~/.grok/hooks/soft-foundry-sessions.json`) and a `find-session` skill for Claude (`~/.claude/skills/find-session/`, which Grok also reads) and Codex (`~/.agents/skills/find-session/`). Every other setting is kept; reinstalling replaces only Soft Foundry's entries; `hooks uninstall --sessions` removes only them. It states that Codex runs the hook only after the person trusts it with `/hooks`. `doctor` reports whether the session hook is installed.
- **REQ-SL-009 (phase runner).** `phase run` records the session it starts: it passes `--session-id <uuid>` to Claude and `-s <uuid>` to Grok, and for Codex looks up the session the hook recorded. `executed_by` gains `session_id` and `cwd`. Grok joins the shells the guard can cover, with the runner's warning saying Grok runs the Claude guard hook only in a folder trusted with `/hooks-trust`.
- **REQ-SL-010 (UI).** A change's page in `soft-foundry ui` lists that change's recorded sessions with their resume commands.
- **REQ-SL-011 (docs).** README, help text, and `.ai/schemas.md` (`executed_by`) describe the ledger, the commands, the install step, Grok coverage, and what the ledger stores. Version 0.18.0.

## Constraints
- The hook must never block or slow a prompt noticeably: no network, no model call, exit 0 on every error, no output.
- Nothing machine-local (the ledger, prompts, other repositories' paths) enters a committed change record or the repository.
- Every new output line carries its status as a word (`.ai/rules/accessibility.md`).
- The guard's decision logic stays host-neutral; only the tool-name mapping widens.
- Commit binding, staleness, and the gate are not weakened.

## Non-goals
- Backing up transcripts. The ledger is an index; a session is resumable only while its agent still has the transcript.
- Semantic or model-based search. Lookup is word matching; the find-session skill lets an agent do the interpretation.
- Installing the hook on this machine as part of the change. Evaluation uses a temporary home directory; installing on the maintainer's real configuration is a separate step they approve.
- Cross-provider review, panels, visual evidence, and tab titles: changes 2 to 5 of the plan.

## Task classification
Feature: a new ledger module, two lookup commands and one hook command, user-level hook and skill installation, guard tool-name mapping, phase-runner session IDs, a UI list, documentation, and tests.

## Initial risk
medium. The session hook runs on every prompt of every agent session on the machine once installed, so a fault in it is felt everywhere (mitigated by fail-open, no output, and a short path). The guard change touches a security control, but only widens what it checks. The ledger stores prompt excerpts on the local disk.
