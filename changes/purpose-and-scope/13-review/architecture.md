# Architecture Review

## Scope reviewed
Where the new text lives and how the pieces refer to each other, against `.ai/rules/general.md`, `.ai/rules/architecture.md` and the layout described in `.ai/README.md`.

- The threat model is stated once, in `.ai/skills/adversarial-testing/SKILL.md`. The review skill restates one sentence of it and points at the file (`05-implementation/decisions.md`, third row). The control plane is in the review skill's read set, so a fresh review session can follow the pointer; this session did.
- The Purpose section is repeated in `README.md` and `.ai/README.md`. The two differ in three places: `README.md` adds the SQL injection example and the sentence "Everything in between runs without them"; `.ai/README.md` adds the pointer to the two skills. The specification asked for the purpose in both files, so the repetition is what was specified.
- No contract file changed: no `skill.yml`, `permissions.yml`, `requirements.yml`, `completion.yml`, template, `workflow.yml` or policy. What every gate checks is the same as before the change, which is the non-goal "Changing what any gate checks".
- `.ai/README.md` gained the heading "Skills and modes" over text that had none. No text was removed from any file.
- The new rule in the review skill sits beside two older rules of the same kind (defensive-addition findings are not blocking or major by default; outside-change findings never block). It adds no new field to the handoff.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-005 | minor | `.ai/skills/review/SKILL.md` line 17; `.ai/skills/adversarial-testing/SKILL.md` line 21 | See functional.md. The follow-up for a repository-write weakness has no single home: `notes` in attack, unnamed in review, and the structured `outside_change` field does not fit a path the change modified. | Two sessions record the same weakness in two places and the follow-up advisory lists only one. | `.ai/rules/general.md` (preserve established conventions); REQ-003 |

No other finding. The purpose text duplicated across two README files can drift (REV-002 is the first case), but the specification chose that layout.

## Conformance
Conforms. One minor finding, shared with the functional review.
