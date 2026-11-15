# Change Intake

## User intent
Make Soft Foundry converge. A change must not loop through remediation more than one or two rounds, and a person, not the evidence phases, decides what a change promises and therefore what is evaluated. The maintainer's words: "the remediation going more than 1-2 rounds is unacceptable. There needs to be human in the loop decision on what will be evaluated so that we are not overpromising."

The request follows an analysis on 2026-11-13 of the change records that carry phase-seal history:

- `readme-workflow-visuals` (risk low, type docs, nine acceptance criteria) has run eight remediation rounds and 36 phase seals since 2026-11-05 and is not finished. Every round's recorded reason is that README wording says more than the code does. Seven of nine criteria were met; the two left open (AC-007 GitHub render, AC-009 opening the published page) can only be satisfied by a person. The blocker in rounds seven and eight, REV-001, is a sentence no criterion asked for, made binding by one catch-all sentence in the specification ("a statement in the diagrams that the code does not support is a defect"). Attack ran 41 cases against the guard itself and its findings about the tool were charged to the document.
- `gate-hardening` (risk high) ran four rounds; those found real defects and are the process working.
- No rule caps the rounds, nothing escalates a looping change to a person, low-risk waivers are opt-in and were not used, an empty `scope` sizes every check at its largest, and each remediation reruns verify, evaluate, attack, review and judge in fresh sessions even for a one-sentence wording fix. The judgment and remediation skills are two lines each and give no threshold for what blocks.
- Specifications for high-risk changes reach 51-55 acceptance criteria, every one binding and every one required to be covered by a check or journey.

## Desired outcome
Each item is an outcome the maintainer must be able to rely on after this change. The specification phase turns them into requirements; this list is the intent.

1. **Remediation is capped at two rounds.** A third remediation of the same change is refused by the tool. The change parks at `status: awaiting_human` and stays there until a person records one of three decisions under `human_decisions`: accept the open findings as residual risk, narrow the claim (a recorded requirement change), or reject. The cap is a human boundary in `.ai/policies/human-boundaries.yml` and the gate checks it.
2. **Acceptance criteria are tiered and a person approves what blocks.** Each criterion carries `tier: must | should`. Only an unmet `must` criterion can block review or judgment; an unmet `should` is an advisory or a follow-up item. The number of `must` criteria is capped by declared risk. Specify cannot seal until a person's approval of the `must` list is recorded. Evaluation and attack direct their cases at the approved `must` list; anything else they find is advisory.
3. **Checks only a person can make are not acceptance criteria.** A criterion that requires a person (open a published page, look at a render on a hosting site) is refused at specify and is carried instead as a release item a person discharges with `change discharge`. A specification may not contain a catch-all rule that makes every statement binding; criteria hold the change only to the cases they name. The specification and documentation skills tell authors to write bounded claims (what is checked, under which conditions, and the known gaps) instead of absolutes.
4. **Findings outside the change do not block it.** A finding about behavior in code the change does not modify becomes a follow-up item recorded in the change, not a blocker for it.
5. **The loop is lighter where risk allows.** A low-risk change skips its waivable phases by default unless the record asks for them, each skip still recorded with a rationale. A change that modifies only documentation gets the smaller check sizes. A remediation that changes only documentation or wording reruns review and judgment, not the whole verify-to-judge tail.
6. **Judgment and remediation have thresholds.** Judgment returns BLOCKED only for an unmet `must` criterion or a blocking finding that names a concrete failure. Remediation fixes blocking and major findings and carries minor ones forward instead of rewriting text that then needs re-checking.
7. **Every new rule is explainable and tested.** Each new gate check has an entry in `Gate::CHECKS`, a harness-eval case that plants the defect it refuses, and a line in the user documentation.
8. **History stays green.** Closed and released records are not re-gated by the new rules; `soft-foundry ci` passes on this branch and on main after merge with every existing record.

## Constraints
- The maintainer approved, on 2026-11-13, that this change intentionally loosens blocking controls (`.ai/policies/human-boundaries.yml`: "changes that intentionally weaken required controls"); recorded under `human_decisions` in `metadata.yml`. The loosening is bounded to the items above: no check that refuses fabricated, stale or hollow evidence is removed, review and judgment stay unwaivable, and a final judgment is still required to close.
- The gate keeps its boundary: it checks structural facts the record asserts, never whether a claim is true. A tier, a cap, an approval and a round count are structural facts.
- The new rules apply to records created or reopened after merge. This change itself runs under the rules on main today.
- The guard stays in block mode in this repository. Text owed under `.ai/**`, `README.md` or harness evals is written under the maintainer's documented warn-mode override and recorded in the implementation handoff, as on previous changes.
- The suite is run with provider keys and `SOFT_FOUNDRY_PHASE` unset before any evidence is recorded.
- Review and judgment run in fresh sessions through `soft-foundry phase run`.

## Non-goals
- A check catalog and runner that tests each area (accessibility, security, docs, behavior) with stable tools. Agreed as the next change, after this one.
- Changing which phases exist, their order, or the two lifecycle tracks.
- Finishing or closing `readme-workflow-visuals` or `release-0-23-0`; both are tabled, their working trees untouched.
- Fixing the guard escapes attack found during `readme-workflow-visuals` (FIND-ATT-025, FIND-ATT-026); they belong to the guard follow-up.

## Task classification
`feature`. Adds gate checks, a remediation cap and a human-boundary entry, criterion tiers and an approval record, changes to default waivers, check sizing and rerun scope, and skill text for specification, documentation, evaluation, attack, review, judgment and remediation. Touches `lib/`, `test/`, `.ai/workflow.yml`, `.ai/policies/`, `.ai/skills/`, `.ai/templates/`, `.ai/harness-evals/`, `docs/user/` and `README.md`.

## Initial risk
`high`, chosen by the maintainer. The change edits the gate and the policies every other change depends on, and it deliberately loosens what blocks. A defect either lets a change through that a person never agreed to, or parks every change. High risk forces the gated track and allows no phase to be waived.
