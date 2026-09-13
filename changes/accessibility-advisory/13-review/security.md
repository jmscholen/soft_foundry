# Security Review

## Scope reviewed
New file reads and writes: `Advisory` reads `metadata.yml`, phase handoffs, `requirements.yml`, `results.md`, `accessibility.md` inside the change record, and `.ai/repository.yml`; `change new` rewrites one line of the `metadata.yml` it just created; the maturity scan checks for one file. No network, no credentials, no environment variables beyond what already existed.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-007 | info | `lib/soft_foundry/advisory.rb` `load` | YAML is loaded with `safe_load_file` and permitted classes limited to Time/Date, matching `ChangeRecord#load`; a malformed file yields `{}` rather than an exception, so a corrupt requirements file cannot crash `gate`. | `.ai/rules/security.md` (untrusted input at boundaries) |
| REV-008 | info | advisory messages | Messages interpolate the skip rationale from `metadata.yml` verbatim. It is repository-controlled text printed to the same terminal that prints the rest of the record, and no escape sequences are added; a rationale containing control characters would reach the terminal as it would through `cat`. Same exposure as every other field the CLI prints. | `.ai/rules/security.md` |

## Conformance
Conforms. No new attack surface beyond the threat_model rationale in `metadata.yml`.
