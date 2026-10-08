# Attack Results

Commit SHA: 2bdc19fbb760243a9e30eda2db7b0c32722d1479

## Authorization envelope
Local CLI processes and the real guard command in a scratch repository; synthetic data; no live agent asked to attack. See `cases.yml`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-001 | blocked_by_scope (reasoned, not run) | evidence/attack-transcript.log |
| ATTACK-002 | THREAT-002 | denied | evidence/attack-transcript.log |
| ATTACK-003 | THREAT-004 | denied | evidence/attack-transcript.log |
| ATTACK-004 | THREAT-003, THREAT-005 | denied | evidence/attack-transcript.log |
| ATTACK-005 | THREAT-002 | denied | evidence/attack-transcript.log |
| ATTACK-006 | THREAT-002 | denied (REM-001 cases: shell, Grep, Glob, staging folders, consensus) | evidence/attack-transcript.log |

## Violations found
None. Second run, after remediation REM-001 (which fixed the review's REV-SEC-001, -002, -003); the first run at d1cf0d6 is superseded.

Residuals: a malformed `SOFT_FOUNDRY_PANEL_MEMBER` is ignored (the skill's own permissions still apply) rather than failing closed; a member cannot change the environment its own hooks receive, so this needs a process outside the panel. Inter-agent prompt injection (ATTACK-001) is mitigated by the prompts and the guard, not prevented.

## Blocked cases and reason
ATTACK-001: asking a live agent to plant instructions for another live agent is outside this phase's envelope (no live agent was asked to attack); recorded as reasoned.
