# Security Review

## Scope reviewed

Provider selection and the same-provider advisory (`phase_provider.rb`, `phase_runner.rb` `default_shell`, `advisory.rb` `same_provider_notices`), the `findings explained` gate check (`gate.rb`), and the skill-yml lint (`check.rb`). Compared with `.ai/rules/security.md`. Threat-model phase was skipped; attack cases ATTACK-001 and ATTACK-002 at `53e4108` were read.

The change does not take a new external input. Handoff YAML is already in the record. The shell that is launched is one of `claude`, `codex`, `grok`, or the person's `--shell`, and an unknown `--shell` still raises before spawn. Provider names are interpolated into a status line, not into a command.

## Findings

None.

## What was checked

- **Allowlist.** `SHELLS` is the only source of the default executable. `default_shell` never passes a string from the handoff to `launch`.
- **Advisory is not a control that fails the gate.** REQ-XP-004 says it must not. A review that writes a different canonical provider (`openai` while the session ran on anthropic) silences it. Attack ATTACK-002 and the implementation decision record that residual: `resolved_model.provider` is agent-written because a shell can be pointed at another provider. Not re-filed.
- **Unrecognized provider string.** `PhaseProvider.of` returns nil for `claude-opus` even when `executed_by.shell` is `claude`. That nil is what makes REV-FUN-001 schedule claude, and it also skips `same_provider_notices` (`next unless own`). The wrong launch is the functional finding. After a session that records a canonical provider, the advisory still names a same-provider review. A deliberate misstatement to another canonical name remains the recorded residual.
- **Gate check.** `findings explained` is structural, as REQ-XP-005 requires. `failure: n/a` passes. Severity `critical`, `High`, and a missing severity fail without `failure:`, which is REM-001. ATTACK-001 at this commit denies those.
- **Secrets and content.** No credential, no new file written outside the record by this behavior, no invisible text in the new lines. The scan evidence at `53e4108` reports 0 errors.

## Conformance

Conforms. The selection bug is a wrong default shell, filed as REV-FUN-001, not a command injection or a skipped authorization check. The two residuals attack already recorded (placeholder `failure:` text, and a canonical provider that is not the shell) stand.
