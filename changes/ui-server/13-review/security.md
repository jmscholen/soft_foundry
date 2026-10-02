# Security Review

## Scope reviewed
The listener, the parser, the route and refusal logic, the response headers, and how record text reaches the DOM, against `.ai/rules/security.md` and the threat model in `03-threat-model/`. The attack results in `08-attack/` were read as evidence, not repeated.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-012 | info | `UI::Server` | Loopback bind with no override; GET and HEAD only; six exact routes; no path from a request; slug checked against the listing; Host check; cross-site data refusal; no CORS; strict CSP. Each has a test and an attack case. | XSS, CSRF, path traversal |
| REV-013 | major (accepted) | whole server | No authentication. Any local process or local user can read the page. The maintainer accepted this for a read-only view. It must be revisited before any write action is added or if the tool is used on a shared host; a per-run token in the URL is the mitigation. | Authorization; THREAT-008 |
| REV-014 | minor | `UI::Server#own_site?` | A client that sends no `Sec-Fetch-Site` is allowed. That is every non-browser client and browsers from before 2023. Same-origin policy still stops a cross-origin page reading the answer, and the Host check stops rebinding, so this is depth, not the only control. | THREAT-002 |
| REV-015 | minor | `UI::Server#cached` | Error text from an exception is returned to the page with the repository root stripped. It can still carry a Ruby message. Local viewer only. | Information exposure |
| REV-016 | minor | `UI::Server#admit` | Eviction makes room for a newcomer by closing the longest-idle connection; a local flood can still race a real connection out before its request is read. | THREAT-006 |
| REV-017 | info | `app.js` | No markup-parsing API appears; every record string goes through `textContent` or `setAttribute`. No `href` or `src` is ever built from record text, so a `javascript:` string cannot become a link. The one `querySelector` built from data escapes quotes and backslashes and uses the page's own keys. | XSS; ATTACK-007 |
| REV-018 | info | records | The page shows record text that an in-progress phase may hold before the content scan has gated it. A secret typed into a handoff would be displayed to the local viewer. | Secrets in generated artifacts |

## Conformance
Conforms, with REV-013 accepted by the maintainer and recorded as a residual risk.
