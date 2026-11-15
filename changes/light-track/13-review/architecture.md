# Architecture Review

Standard: `.ai/rules/architecture.md`, `general.md`, `ruby.md`, `testing.md`, `errors.md`.

## Scope reviewed
The design choices in `05-implementation/decisions.md` against the diff, and where the new behavior sits: the track as configuration in `.ai/workflow.yml`, path and round rules in `ProcessRules`, sizing in `Sizing`, the status wording in `ChangeRecord#skip_reason` and `cli.rb`.

## Assessment
- The track as a `tracks:` entry with an `optional:` list, and no new gate code, is the simplest design that meets REQ-001 and REQ-002. It reuses the rule built for the iterative track, so the gate, the seal, the runner and `change close` cannot disagree about a light record.
- `text_only_path?` is separate from `documentation_path?`, so the documentation-only remediation seal keeps refusing control-plane edits. The decision is recorded and a test holds it.
- `normalize_path` is a pure function used on both sides of the comparison in the gate. Refusing what cannot be normalized, instead of resolving it against the machine, keeps the check repeatable.
- RED commit a53ec00 holds only the test file; GREEN c6bf4eb adds two lines of setup to one test and no assertion (DEV-002). The testing rule's order is followed.
- No rescue was widened, no dependency added, no dead code found.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | `lib/soft_foundry/phase_reopen.rb`, `process_rules.rb` | See functional.md. The design point: "was this round sealed" is answered from a commit subject shared by every round, so the answer is about the phase, not the round. | See functional.md | general.md: make invariants enforceable |
| REV-010 | minor, outside this change | `lib/soft_foundry/check.rb` `check_tracks` (not modified) | `check` verifies that a track's `optional:` names real phases. It does not refuse a track that names `review`, `specify`, `implement` or `verify` as optional; only judgment is protected, in `reached_lifecycle_end?`. `waivable_by_risk` has that lint and tracks do not. Read from the code, not run. Using it needs write access to `.ai/workflow.yml`, so it is a follow-up. | | general.md: make invariants enforceable; `.ai/README.md` (review and judgment never waived) |
| REV-013 | minor | `ChangeRecord#skip_reason`, `Snapshot#skip_reason` | Two functions now answer why a phase may stay pending, with different orders and vocabularies (`Snapshot` has no case for a default waiver at low risk). The browser view and `change status` can label the same phase differently. | | architecture.md: avoid hidden coupling |

## Conformance
Conforms with the minor findings above. The decisions with lasting consequence are recorded in `05-implementation/decisions.md`.
