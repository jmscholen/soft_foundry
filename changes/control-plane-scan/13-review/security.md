# Security Review

## Scope reviewed
A security control reviewed for how it fails: what it reads, what it misses, how it can be silenced, and what it leaks.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-009 | info | `ContentScan.scan_text` | A finding's detail names a secret's shape, never its value, so the scan's own output (in `check`, `ci`, a transcript) does not become a leak. Tested. | `.ai/rules/security.md` |
| REV-010 | minor | silencing | Two ways to silence a finding: the in-line marker (visible in the diff of the file it silences) and the policy file (protected from every skill's write set, changed only through a record, reason required). An agent under the guard cannot write the policy file; it can add the marker to a file it may write. The marker cannot silence invisible text, which is the kind an agent would use to hide something. | `.ai/policies/skill-permissions.yml` |
| REV-011 | info | coverage | `learned.md` is under `.ai/rules/` and therefore scanned by `check` on every run, answering learning-instincts REV-010; the four promoted sections scan clean. | learning-instincts REV-010 |
| REV-012 | info | the canary exemption | Narrow by path, kind, and substring; a real key in the same directory that is not the canary would still be flagged. | `.ai/rules/security.md` |

## Conformance
Conforms.
