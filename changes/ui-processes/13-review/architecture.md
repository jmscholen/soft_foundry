# Architecture Review

## Scope reviewed
Where process discovery sits and what depends on it.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-008 | info | `Processes` | Delivery-neutral: the CLI and the server call it; both sources (`ps`, working directory) are injectable, so every parsing rule is tested without a process. | Domain not in the delivery mechanism |
| REV-009 | minor | `Processes::COMMANDS`, `SUBCOMMANDS` | The command vocabulary is restated from the CLI's dispatch. A new command must be added in two places or it will not be listed. | Single source of truth |
| REV-010 | info | `Processes#branch_change` | The third copy of branch-to-slug resolution (CLI, Guard, here). | Duplication; follow-up |

## Conformance
Conforms.
