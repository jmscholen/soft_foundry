# Assumptions

## Explicit assumptions
- Shell to provider: claude is Anthropic, codex is OpenAI, grok is xAI. A shell may be pointed at another provider (Claude Code with a third-party model, say); the handoff's `resolved_model.provider`, which the phase's agent fills, is preferred over the shell for that reason.
- "Installed" means the shell's executable is on `PATH` (the existing `Shell.resolve`), not that it is logged in.
- Change 1's records give the real shapes: `resolved_model.provider` was written as `anthropic` by the implementing session and `xAI` by the Grok reviewer, so matching is case-insensitive.

## Ambiguities resolved
- Which earlier phases count: both implementation and remediation, because remediation changes code too. A provider is counted only from a phase that is complete.
- Order among acceptable shells: the runner's existing order (claude, codex, grok). With Claude-implemented work, that picks Codex when it is installed.
- Severity names: the review templates use blocking, major, minor; `failure:` is required for blocking and major.

## Ambiguities that block safe progress
None.
