# Infrastructure Review

## Scope reviewed
No Infrastructure as Code is present in or modified by this change. One library file is added, packaged by the existing glob; nothing under `.ai/`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-022 | info | runtime needs | `ps` (and `lsof` on systems without `/proc`) must be on PATH. Both are present on macOS and on common Linux images; a minimal container may lack `ps`, and the command then says the list could not be read. | `.ai/rules/dependencies.md` |

## Conformance
N/A: no infrastructure is present or modified.
