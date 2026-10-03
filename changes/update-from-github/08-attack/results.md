# Attack Results

Commit SHA: b7764e2687a9290cdbbec2901cc444e95756ff35

## Authorization envelope
The updater in this checkout with replaced network responses, and the public repository's own source. Nothing published; no other host.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 | THREAT-001 | denied | tests |
| ATTACK-002 | THREAT-001 | denied | tests, network transcript |
| ATTACK-003 | THREAT-003 | blocked_by_scope | reasoned only |

## Violations found
None.

## Blocked cases and reason
ATTACK-003 was not run: it needs a redirecting server, and the real-download path has no injected HTTP seam. It is the one mitigation in this change that rests on reading the code. THREAT-002 (archive traversal) is accepted as `tar`'s own protection and was not attacked.
