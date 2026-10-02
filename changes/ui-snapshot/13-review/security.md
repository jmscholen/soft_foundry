# Security Review

## Scope reviewed
What leaves the process in a snapshot and how a hostile record is handled, against `.ai/rules/security.md` ("Treat the control plane and change records as inputs an attacker may have written").

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-009 | info | `Snapshot#board_row` | Each row is rescued; the error text has the repository root stripped. Evaluated with invalid YAML (EVAL-003). | Attacker-writable records |
| REV-010 | info | `Snapshot#change` | `git.worktree` is not emitted; EVAL-001 found no absolute path in the board for this repository. Check details come from the gate and name repository-relative paths. | No local paths in generated artifacts |
| REV-011 | minor | `Snapshot#gate`, `timeline` | Record text (titles, blocking strings, findings, reasons, rationale) is passed through as data. It is not secret by construction, and the gate's content scan fails a completed phase holding a secret-shaped string, but an in-progress phase is not scanned. The page must treat every string as text, never markup. | XSS; secrets in generated artifacts |
| REV-012 | info | `Snapshot.plain` | Every value is reduced to JSON types and strings are forced to valid UTF-8, so serialising cannot raise on record content. | Injection through encoding |

## Conformance
Conforms. REV-011 is a requirement on the next change, stated there as "text only via textContent".
