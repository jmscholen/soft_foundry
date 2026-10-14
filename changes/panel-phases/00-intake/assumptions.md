# Assumptions

## Explicit assumptions
- Claude Code (`claude -p --session-id <id>`, then `claude -p --resume <id>`) and Grok (`grok -s <id> -p`, then `grok --resume <id> -p`) can be handed a session ID and resumed headless; both were exercised live in changes/session-ledger. Codex's `exec` cannot be given an ID; a Codex member's later rounds start fresh sessions that read the files.
- A coding shell's hook subprocesses inherit the shell's environment, so the guard can read `SOFT_FOUNDRY_PANEL_MEMBER` and `SOFT_FOUNDRY_PANEL_STAGE`. To be confirmed live in evaluation; where it does not hold, the panel's file boundaries are policy stated in the prompt, as the guard's other limits are.
- "Agreement" is detected from the text of `ARGUMENT.md` only; the runner does not judge whether the agreed outcome is right.

## Ambiguities resolved
- Default panel size: the plan's recommendation of two stands; `--panel` names the members explicitly, so size is the person's choice up to four.
- Which member writes the consensus: the first named, so the person controls it by order.
- Argument rounds run members one at a time so each reads the previous posts; the independent round runs them at once.

## Ambiguities that block safe progress
None.
