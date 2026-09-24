# Assumptions

## Explicit assumptions
- Codex's hook contract is as its published documentation states at the time of this change (`.codex/hooks.json`, `PreToolUse`, `tool_name`/`tool_input` on stdin, exit 2 to refuse, `Bash` and `apply_patch` as tool names, array commands, the `/hooks` trust step). The installed `codex --version` is 0.139.0 and its help mentions `--dangerously-bypass-hook-trust`, consistent with that contract. A live Codex session did not run through the guard in this change; the payloads in the tests and journeys follow the documented shape.
- Grok 1.0.30's `-p`/`--single` is its single-turn headless form (from `grok --help`), and it has no hook mechanism (its help mentions none). If Grok gains one, the runner's `HOOKED_SHELLS` and an installer are the two places to change.
- The apply_patch header lines are the documented four; a patch with other header forms yields no paths and is allowed as "no file path", which is the conservative pass-through the guard already uses for unknown tools.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, on the gated track, and the review and learning phases are run for it. That choice is recorded here rather than silently assumed.

## Ambiguities resolved
- Whether Codex's `Read` tool should be matched: Codex's documentation lists no `Read` tool (reads happen through the shell), so the matcher is `Bash|apply_patch|Edit|Write`; a `Read` payload from any host is still handled by the guard if it arrives.
- Whether `--local` should apply to Codex: no. Codex's documented project scope is one file; the flag is refused with the reason rather than silently ignored.
- Whether `doctor` should keep one line per host: no. One line with both states keeps every line status-worded and stops a repository that uses only one host from failing `doctor` on the other.

## Ambiguities that block safe progress
None.
