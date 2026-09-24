# Architecture Review

## Scope reviewed
`Learning` as a module of functions over records; the gate check delegating to it; the CLI owning refusal and printing; the rules file as the ledger.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-006 | info | `lib/soft_foundry/learning.rb` | Validation (`problems`), reading (`read`, `all`), policy (`min_confidence`), and writing (`promote!`) are separate functions; the gate uses the first two, the CLI all four. | `.ai/rules/architecture.md` |
| REV-007 | info | `lib/soft_foundry/cli.rb` `learn` | The command decides what to promote (already, below, dry run, chosen) and `Learning.promote!` only writes; same split as `vet`/`vet!`. | `.ai/rules/architecture.md` |
| REV-008 | info | `.ai/rules/learned.md` | The rules file is the promotion ledger (headings are ids), so there is no second file to keep in step. | `.ai/rules/architecture.md` |
| REV-009 | minor | `Learning::HEADER` and `.ai/rules/learned.md` | The header text lives twice: in the shipped file and in the module (for a repository that deleted the file). Follow-up: read the shipped template instead. | `.ai/rules/architecture.md` |

## Conformance
Conforms.
