# Functional Review

## Scope reviewed
Commit 58447638713364d48123cc4b810febff909b52a3 (HEAD, `Record purpose-and-scope evaluate`). Outside `changes/` it is identical to the implementation commit d944d07: `git diff --name-only d944d07 HEAD` lists no path outside the record.

Read in full at that commit: the patch of d944d07 (38 added lines in `README.md`, `.ai/README.md`, `.ai/skills/adversarial-testing/SKILL.md`, `.ai/skills/review/SKILL.md`), the four files around the added text, `02-specification/` (REQ-001 to REQ-006, AC-001 to AC-006), `05-implementation/`, `06-verification/results.md` and handoff, `07-evaluation/results.md` and handoff, `.ai/workflow.yml`, `.ai/schemas.md`, `.ai/policies/human-boundaries.yml`, `.ai/skills/final-judgment/SKILL.md`, and the baseline rules `general.md`, `security.md`, `accessibility.md`.

Each criterion was read against the text by this session, not taken from the earlier phases.

| Criterion | Tier | Result | Where |
| --- | --- | --- | --- |
| AC-001 | must | met | `README.md` lines 5 to 11 and `.ai/README.md` lines 5 to 11: `## Purpose` is the first section after the title, before any section on commands or layout. Both say "autonomous software factory", "What each gate checks is locked once a person approves it", and that verification, evaluation and attack look at the feature from the outside. |
| AC-002 | must | met | `.ai/skills/adversarial-testing/SKILL.md` lines 5 to 21: outside party reaching the change through requests, parameters, uploads, jobs, webhooks, command arguments; nine numbered classes in the order of REQ-002; repository-write editing of the change record, the control plane or git history is out of scope and noted as a follow-up, with no severity. |
| AC-003 | must | met | `.ai/skills/review/SKILL.md` line 17: graded against the attack threat model; a finding that needs write access to the repository is never graded blocking or major; "Record it as a follow-up." |
| AC-004 | should | met | `README.md` lines 9 and 11: lock and detect, and the three points where a person steps in. |
| AC-005 | should | met | See accessibility.md. |
| AC-006 | should | met | `git diff --name-only 49b2ae5 HEAD -- lib exe test` lists nothing. `soft-foundry check` run by this session in the worktree: pass, 16 phases, 17 skills, no errors. `soft-foundry ci` was not rerun here; the passing run is `06-verification/evidence/ci.txt` for the same tree outside `changes/`. |

The attack phase did not run: at low risk it is stepped over by default (`default_waivers`), and the change adds no code an outside party can reach. There is no attack evidence to review.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-002 | minor | `README.md` line 11 | "Everything in between runs without them" is wider than the three points REQ-004 asked for and is not true of the tool. `.ai/policies/human-boundaries.yml` lists other stops (panel split, policy text owed, budget cap, deploy beyond development, weakening a control, which this change itself needed), and `README.md` lines 258 and 364 describe two of them. `.ai/README.md` does not carry the sentence. Confirms EVAL-F1. | A person adopting the tool reads Purpose, plans for three stops, and finds a change parked at `awaiting_human` for a fourth reason. | REQ-004; specification "Data and consistency" (the two README files agree) |
| REV-004 | minor | `.ai/skills/adversarial-testing/SKILL.md` lines 3, 9 to 19, 43 | The new section does not say whether the nine classes are the whole list. The opening paragraph and "Purpose of ATTACK" still name replay, concurrency, malformed or large input, retry behavior and dependency failures. Confirms EVAL-F2. | A fresh attack session reads the numbered list as complete and does not try a replay or a concurrent request against a new endpoint. | REQ-002 |
| REV-005 | minor | `.ai/skills/review/SKILL.md` line 17; `.ai/skills/adversarial-testing/SKILL.md` line 21 | The two skills record the same weakness in different ways. Attack: handoff `notes`, no severity. Review: "Record it as a follow-up", with no place named. The only structured follow-up field (`outside_change` with `follow_up` and `paths`) is refused by the gate when the path is one the change modified, which a change record always is. | Two review sessions record the same weakness in two places (a minor finding, or a line in `notes`), and the follow-up advisory lists one and not the other. | REQ-003; specification "Data and consistency" |
| REV-006 | minor | `README.md` lines 3, 7, 13 to 22 | The file opens with two descriptions four lines apart ("control plane ... eventually enforced lifecycle orchestration", then "autonomous software factory"), and the section after Purpose names `init-command` as the next milestone, which is long finished. Confirms EVAL-F3 and IMPL-001. Not asked for by the specification. | A newcomer reads "eventually enforced" and concludes the gates are not in force yet. | none; outside what the specification asked |

Not a finding: both README files say "editing a change record" where the skill says "the change record, the control plane or git history". The shorter form is a summary of the longer one and does not contradict it.

## Conformance
Conforms. The three must criteria and the three should criteria are met at the commit. Four minor findings, none of them an unmet criterion; each is wording for a later documentation change.
