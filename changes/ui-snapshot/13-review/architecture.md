# Architecture Review

## Scope reviewed
Dependency direction and duplication, against `.ai/rules/architecture.md` and `.ai/rules/general.md`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-005 | info | `snapshot.rb` | Requires only domain classes; knows nothing of the CLI or of HTTP. The CLI and, later, the server call it. | "Domain behavior should not depend directly on delivery mechanisms" |
| REV-006 | info | `change_index.rb` | Replaces three private CLI methods and an inline test in `ci`; no new abstraction beyond what two callers already need. `Guard` still has its own branch-to-slug logic, which this change did not touch. | "New abstractions must solve a demonstrated problem" |
| REV-007 | minor | `Gate.checks_for` and `Gate#evaluate` | The conditions for phase-specific checks are written twice. Acceptable while a test ties them together (see REV-004); a single table driving both would remove the duplication. | `.ai/rules/general.md`, simplest design |
| REV-008 | info | `gate.rb` | Now requires `change_record`, which it already depended on at run time. No cycle. | Dependency direction |

## Conformance
Conforms.
