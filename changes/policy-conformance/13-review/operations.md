# Operations Review

## Scope reviewed
What an operator sees and does differently after this change: the `! warn policy:` lines on `gate`, `change status`, `ci`, and `change close`; the `check` warning; the level-5 maturity requirement; the `policies:` block written by the scan; the auto-set flag on `change new`; the `awaiting_human` and `human_decisions` workflow.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-021 | info | `README.md`, `.ai/schemas.md`, `AGENTS.md`, `.ai/rules/README.md` | The flag, the block, `human_decisions`, and the advisory semantics are documented in every place an operator or agent reads, with the `awaiting_human` path spelled out. | `.ai/rules/general.md` (new behavior must be detectable and explained) |
| REV-022 | info | `.ai/maturity.yml` level 5 | Adding a required capability can lower an already-assessed repository's reported level on its next reassessment until `.ai/rules/policy-conformance.md` is installed; installing the standard is the whole remedy and `check` names it. This repository's own profile already records PASS. | `.ai/maturity.yml` assessment rules |
| REV-023 | minor | `soft-foundry onboard --maturity scan --reassess` | A reassessment rewrites `.ai/repository.yml` from scratch, so a hand-written `policies:` block (this repository's MISSING with rationale, or any discovery-written MISSING) is flattened back to the scan's UNKNOWN. Pre-existing behaviour for every hand-written capability, now with one more block affected. A merge-preserving reassess, or a deep assess that reads the existing block, is the follow-up. | `.ai/README.md` (repository.yml is evidence, refreshed by discovery) |
| REV-024 | info | this change record | Running `gate all --change policy-conformance` prints its own advisory block (judgment skipped; accessibility requirements not recorded because specification is skipped). That is the feature working on itself, and the maintainer should read those lines before merging. No policy advisory appears because the flag is correctly false and no document is recorded PASS. | REQ-POL-006 |
| REV-025 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan` although the CLI accepts only `--maturity scan` (REV-001 of the accessibility-advisory review). The evaluation used the working spelling. Still open. | `.ai/rules/accessibility.md` (documentation sends the user to a wrong spelling) |

## Conformance
Conforms.
