# Security Review

## Scope reviewed

`.ai/rules/security.md` applied to provider selection, the process the runner launches, the same-provider advisory, and `findings explained`. Threat model was skipped; the intake's attack surface is the runner reading handoffs it already reads and choosing among shells the person already runs. Attack cases ATTACK-001 and ATTACK-002 at `a963a27` were read. No new network endpoint, credential, or trust boundary was added.

## Findings

None.

## What was checked

The launched executable is `Shell.resolve` of a name in `PhaseRunner::SHELLS` (`claude`, `codex`, `grok`). `default_shell` only returns one of those keys, or `"claude"` when nothing is on `PATH`. `--shell` still goes through `SHELLS.fetch`, which raises on an unknown name. A handoff cannot choose the executable.

The printed line is built from phase ids (`implementation`, `remediation`) and from `PhaseProvider`'s three canonical names. The raw `resolved_model.provider` string is not interpolated into the command or the message, so a provider value with a newline or a shell metacharacter does not reach the child process.

`findings explained` is a structure check, as REQ-XP-005 requires. It does not execute finding text.

Secrets: the change reads provider names and shell keys already stored in the handoff. It does not log credentials. The test unsets `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, and `XAI_API_KEY` around the dry-run.

## Residuals attack already recorded

These are not new findings. Both are the behavior the intake and `05-implementation/decisions.md` chose.

- `failure: n/a` passes. The gate checks that `failure:` is non-empty, not that it names a real failure. ATTACK-001.
- A review handoff that writes a recognized provider other than the shell it ran on silences the same-provider advisory, because `resolved_model.provider` is agent-written and wins over `executed_by.shell`. The same rule steers `default_shell`: implementation recorded as `openai` with shell `claude` makes review pick claude. ATTACK-002 and the decision "a shell can be pointed at another provider".

## Conformance

Conforms. REV-FUN-001 was a wrong default, and it is fixed. Nothing in the fix opens an injection path or disables a control.
