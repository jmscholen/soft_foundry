# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| HEVAL-SL-001 | `phase run --shell <each installed shell>` launches a one-turn session that the shell accepts | REM-001 | Each installed shell exits 0 and the session ID in `executed_by` resolves with that shell's own session lookup |
| HEVAL-SL-002 | A ledger line planted with a shell-syntax `session_id` | REV-SEC-001 | `sessions` and `resume` print no command for it, or print it quoted |
