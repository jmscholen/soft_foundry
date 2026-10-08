# Attack Results

Commit SHA: 0370e02436d1b5a2a60fdaa057db67d19dabd158

## Authorization envelope
Local CLI processes and a scratch repository; synthetic handoffs; nothing destructive. See `cases.yml`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | gate check bypass | violated | evidence/attack-transcript.log |
| ATTACK-002 | advisory silenced | denied (with a recorded residual) | evidence/attack-transcript.log |

## Violations found
- **FIND-ATK-001 (major).** `findings explained` checks only severities spelled `blocking` or `major`. A review that calls a serious finding `critical` (or `high`) carries it with no failure named, and the check reports "no blocking or major findings". Fix: require `failure:` for every severity except `minor`. Goes to remediation.

Residuals, not violations: `failure: n/a` passes (the check is structure-only, as REQ-XP-005 says); a review handoff that misstates its own provider silences the advisory (`resolved_model` is agent-written).

## Blocked cases and reason
None.
