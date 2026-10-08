# Attack Results

Commit SHA: a963a27e4fc34e5200aa212bbc9d51d67e293cd1

## Authorization envelope
Local CLI processes and a scratch repository; synthetic handoffs; nothing destructive. See `cases.yml`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | gate check bypass | denied (after REM-001) | evidence/attack-transcript.log |
| ATTACK-002 | advisory silenced | denied (with a recorded residual) | evidence/attack-transcript.log |

## Violations found
None at this commit. Found in the first run, at 0370e02, and fixed by remediation REM-001:

- **FIND-ATK-001 (major).** `findings explained` checks only severities spelled `blocking` or `major`. A review that calls a serious finding `critical` (or `high`) carries it with no failure named, and the check reports "no blocking or major findings". Fix: require `failure:` for every severity except `minor`. Fixed in 53e4108; the `critical` case is now refused.

Residuals, not violations: `failure: n/a` passes (the check is structure-only, as REQ-XP-005 says); a review handoff that misstates its own provider silences the advisory (`resolved_model` is agent-written).

## Blocked cases and reason
None.
