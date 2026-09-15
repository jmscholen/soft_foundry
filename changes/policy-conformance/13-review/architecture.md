# Architecture Review

## Scope reviewed
Placement of the policy logic relative to `Advisory`, `ChangeRecord`, `MaturityScan`, and `Check`; the shared `requirement_notices`; the class-level `Advisory.ui_frameworks` and `Advisory.policy_documents`; the `human_decisions` block in change metadata.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-005 | info | `lib/soft_foundry/advisory.rb` | Policy notices sit beside accessibility notices in the same read-only class with the same shape (standard missing, surface undeclared, surface declared with specification and review checks), and the two share one `requirement_notices`. A third surface later is one more block and one more call. | `.ai/rules/architecture.md` (cohesive responsibilities) |
| REV-006 | info | `Advisory::POLICY_DOCUMENTS` vs `MaturityScan::POLICY_DOCUMENTS` | Two constants keyed by the same three names: the advisory's is the list of profile keys, the scan's maps those keys to basename patterns. Extending the set of documents means extending both, as with `UI_FRAMEWORKS` and `detected_frameworks` before. Recorded in `decisions.md`. | `.ai/rules/general.md` |
| REV-007 | info | `lib/soft_foundry/change_record.rb` `declare_surfaces!` | Two regex text edits on a file the same method just wrote, each guarded on its own line's shape and a no-op when nothing matches. A template restructure must keep both lines' shape or the flag silently stays false, which the undeclared-surface advisory would then report. | `.ai/rules/general.md` (side effects explicit) |
| REV-008 | info | `metadata.yml` `human_decisions` | A generic mechanism (boundary, subject, decided_by, decided_at, decision) rather than a policy-specific field, so budget approvals and destructive-operation approvals can use the same block later. Today only the policy advisory reads it. | `.ai/schemas.md` |

## Conformance
Conforms.
