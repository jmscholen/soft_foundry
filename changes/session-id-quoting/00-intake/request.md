# Change Intake

## User intent
The session-ledger change (PR #42) was judged APPROVED_WITH_RESIDUAL_RISK with REV-SEC-001 as its first residual: resume commands shell-quote the folder but insert the session ID read back from the ledger as it is. `record` refuses a bad ID from a hook payload, but a line written into `~/.soft-foundry/sessions.jsonl` some other way (a hand edit, another tool, an agent with file access) is trusted when it is printed, so a pasted command could do more than resume. The maintainer chose to fix it as its own small change, stacked on change 1, before change 2.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-SQ-001.** A ledger line whose `session_id` is not a plain identifier (the pattern `record` already enforces), or whose `agent` is not claude, codex, or grok, is never returned by lookup: `sessions` (text and JSON), `resume`, the runner's Codex lookup, and the UI's recorded sessions all skip it. The line itself stays in the file, untouched.
- **REQ-SQ-002.** Every resume command shell-quotes the session ID as well as the folder, so even a value that bypassed the check could not run as a command.
- **REQ-SQ-003.** Version 0.18.1.

## Constraints
- No change to what `record` accepts or to the ledger format.
- Lines that do not pass are kept in the file (the ledger is the person's data), as unparseable lines already are.

## Non-goals
- REV-SEC-002 (constraining `SOFT_FOUNDRY_SESSIONS`) and the other minor review findings from PR #42.
- Detecting or reporting tampering.

## Task classification
Security fix: one validation on read, one quoting on output, tests, and a RED commit.

## Initial risk
low. Two small edits in `lib/soft_foundry/session_ledger.rb`; lookup can only show fewer entries than before, never more.
