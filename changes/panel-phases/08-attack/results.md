# Attack Results

Commit SHA: 4f3b2dadb445605f059bc1ff942d0de183d35044

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
| ATTACK-008 | THREAT-002 | denied (repository-wide comparison, REM-003) | evidence/attack-transcript.log |
| ATTACK-007 | THREAT-002 | denied (runner fingerprints, REM-002) | evidence/attack-transcript.log |
| ATTACK-006 | THREAT-002 | denied (REM-001 cases: shell, Grep, Glob, staging folders, consensus) | evidence/attack-transcript.log |

## Violations found
None. Fourth run, after remediations REM-001 (REV-SEC-001..003), REM-002 (REV-SEC-004..006), and REM-003 (REV-SEC-007..010); earlier runs are superseded. The guard's shell parsing can be evaded by hiding a path in a variable; the runner's fingerprints are the boundary that holds.

Residuals: a malformed `SOFT_FOUNDRY_PANEL_MEMBER` is ignored (the skill's own permissions still apply) rather than failing closed; a member cannot change the environment its own hooks receive, so this needs a process outside the panel. Inter-agent prompt injection (ATTACK-001) is mitigated by the prompts and the guard, not prevented.

## Blocked cases and reason
ATTACK-001: asking a live agent to plant instructions for another live agent is outside this phase's envelope (no live agent was asked to attack); recorded as reasoned.

Remaining residual (REV-SEC-009, mitigated not closed): members are not sandboxed; a member that searches the system temporary folder can read another's staged draft. Identical copies fail the panel; a paraphrased copy would not be caught.
