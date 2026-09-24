# Architecture Review

## Scope reviewed
Placement of the check in `Gate`, the advisory beside its siblings, the one new git primitive, and the shape of `tests.yml`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-006 | info | `lib/soft_foundry/gate.rb` | `red_evidence_check` follows `specification_lock_check`'s pattern: a phase-specific check appended after the common ones, reading a file the phase owns and asking git. The phase id is matched by name (`verify`), like `specify` above it. | `.ai/rules/architecture.md` |
| REV-007 | minor | `lib/soft_foundry/gate.rb` `red_evidence_check` | The method is long (one loop, five reasons). Each reason is a requirement clause and reads top to bottom, but a small `RedClaim` value with a `problem` method would make the loop three lines. Follow-up. | `.ai/rules/architecture.md` |
| REV-008 | info | `lib/soft_foundry/git.rb` `file_at?` | One `cat-file -e sha:path`, the smallest possible question. | `.ai/rules/architecture.md` |
| REV-009 | info | `tests.yml` fields | Optional per-check fields rather than a separate RED ledger keep the claim beside the check it belongs to; a reader sees the test, its evidence, and its RED commit in one place. | `.ai/schemas.md` |

## Conformance
Conforms.
