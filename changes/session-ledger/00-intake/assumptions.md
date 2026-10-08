# Assumptions

## Explicit assumptions
- The shared plan's four open decisions had no answer recorded when work began; the maintainer said "go ahead and start working on the plan", so its stated recommendations stand: the hook is installed at user level, the ledger stores masked prompt excerpts, panels default to two members (change 3), and the UI feedback box is deferred (change 4).
- Grok facts were checked live on 2026-10-07 against Grok 1.0.30 in a throwaway repository with folder trust disabled for the process: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, and `SessionEnd` hooks fire; payloads carry both camelCase and snake_case keys (`session_id`, `cwd`, `prompt`, `tool_name`, `tool_input`, `transcript_path` on tool events); exit 2 refuses a tool call; hooks from `.claude/settings.json` run with Claude matchers mapped to Grok's tools; tool names are `write` (`file_path`), `search_replace` (`file_path`), `read_file` (`target_file`), and `run_terminal_command` (`command`); `grok -p -s <uuid>` uses the given ID; `grok -p --resume <id>` continues a session.
- Claude Code 2.1.293 has `--session-id <uuid>`, `--name`, and `--resume <id>`; its `UserPromptSubmit` payload carries `session_id`, `cwd`, `prompt`, and `transcript_path` (per the gist and Claude Code's hook contract).
- Codex 0.139.0: `codex exec --json` emits `{"type":"thread.started","thread_id":...}` first (checked live); `codex resume <id>` resumes; its user-level hooks file is `~/.codex/hooks.json` with a `UserPromptSubmit` event (per the gist and Codex's hook documentation). A live Codex model turn could not run here: the local Codex login has expired. Codex behavior beyond the `thread.started` event is therefore from documentation, and is listed as unverified in verification and evaluation.

## Ambiguities resolved
- Where Grok's hook goes: `~/.grok/hooks/` (always trusted). Grok also runs `~/.claude/settings.json` hooks, so both may fire for one Grok prompt; recording is an idempotent upsert keyed by agent and session ID, so a double fire changes nothing.
- How the logger tells agents apart: Grok by its camelCase `hookEventName` key; Claude and Codex by the `--shell` flag their own hook entry passes.
- Phase runner and Codex: Codex cannot be given a session ID up front, so the runner records the newest Codex session the hook logged in the repository after the run started; if the hook is not installed, `session_id` stays null.

## Ambiguities that block safe progress
None.
