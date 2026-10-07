# Attack Results

Commit SHA: 98b55d14586da5d7ce8485d1148cb9bec48907a1 (the transcript header shows the record commit 1644e27 checked out; it changes no APP, TESTS, or INFRA file after 98b55d14586da5d7ce8485d1148cb9bec48907a1)

## Authorization envelope
Local CLI processes in a throwaway directory with synthetic data and a temporary HOME; no network; no real agent configuration touched; destructive actions prohibited. See `cases.yml`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-001 | denied | evidence/attack-transcript.log |
| ATTACK-002 | THREAT-003 | denied | evidence/attack-transcript.log |
| ATTACK-003 | THREAT-002 | denied | evidence/attack-transcript.log |
| ATTACK-004 | THREAT-004, THREAT-006 | denied | evidence/attack-transcript.log |
| ATTACK-005 | THREAT-005 | denied | evidence/attack-transcript.log |
| ATTACK-006 | THREAT-008 | denied | evidence/attack-transcript.log |
| ATTACK-007 | THREAT-007 | denied | evidence/attack-transcript.log |
| ATTACK-008 | THREAT-009 | denied | evidence/attack-transcript.log |

## Violations found
None. Two minor findings, not violations:
- FIND-ATK-001: a prompt whose payload exceeds 1 MB is not recorded (the read stops at 1 MB, so the JSON does not parse). The session is recorded at its next ordinary prompt. Fail-safe by design (MIT-005); worth a README line.
- FIND-ATK-002: a folder whose name contains control characters is recorded without them, so its session reports "folder missing" and its resume command would not reach it. Safe direction; such folder names are rare.
- Residual (TM-001, confirmed): an unmapped Grok tool name such as `edit_file` passes the guard as "not guarded".

## Blocked cases and reason
None.
