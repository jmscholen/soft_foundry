# Security Review

## Scope reviewed
The token, the registry and its ids, what a request can select, and what the wider reach exposes, against `.ai/rules/security.md` and `03-threat-model/`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-012 | info | token | 24 random bytes from `SecureRandom`; header only; fixed-length constant-time comparison; refused in the query string and as a cookie; a preflight for the header is refused. This closes the no-authentication finding carried since ui-server (REV-013 there, REV-013 and REV-030 in ui-processes). | Authentication |
| REV-013 | minor | token lifetime and storage | A bearer secret printed to the terminal, valid for the whole run, kept in the tab's session storage, and readable by any script in the page's origin. An injection in the page would now also yield the token; the page's text-only rule and CSP are what stand in the way. | Secrets handling |
| REV-014 | info | repository selection | Only issued ids; a path, traversal, a near-miss id, and an empty value are all 404; a slug is checked against its own repository. | Path traversal |
| REV-015 | minor | discovery | Any process of the user can cause the server to read a directory by running something named like a coding shell inside it, if the directory has `.ai/workflow.yml`. What is read is rendered as text. This widens "attacker-writable records" from the repository you chose to any repository something is running in. | Attacker-writable input |
| REV-016 | minor | registry | No upper bound (THREAT-005). | Resource exhaustion |
| REV-017 | info | static files | Served without the token; they contain no repository data and no token (ATTACK-001). | Data exposure |
| REV-018 | minor | `soft-foundry ps` | Unchanged and needs no token: it lists the same sessions to anyone who can run it, which is anyone who can run `ps`. The token protects the page's richer view (records, gates, titles), not the fact that sessions exist. | Consistency |

## Conformance
Conforms. The standing accepted risk (no authentication) is resolved; REV-013 and REV-015 are the new things to know.
