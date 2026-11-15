# Change Intake

## User intent
The maintainer restated what Soft Foundry is for on 2026-11-14, after the process-speed change stalled on findings about someone editing its own record. In the maintainer's words: the repository is "an autonomous software factory where we have gated processes that cant be changed and are locked to prevent changes to the specs for each gate. Agent should not change the spec it is tasked with meeting. Verification, attack, etc. should be focused on what an external party expects of the feature and what a bad actor might want to attempt in bypassing the feature to implement some bad action, like sql injection."

This change writes that purpose into the repository and points the attack and review skills at it.

## Desired outcome
- `README.md` and `.ai/README.md` state the purpose: an autonomous software factory in which an agent builds a feature in an application through gated phases; what each gate checks is locked once a person approves it; verification, evaluation and attack look at the feature from the outside.
- The adversarial-testing skill names the attacker: an outside party who reaches the change through what it exposes. It lists what to try against the code the change added or modified (injection, cross-site scripting, broken authorization, identifier substitution, mass assignment, path traversal, server-side request forgery, data exposure, resource exhaustion). It states that a party with write access to the repository editing the change record, the control plane or git history is out of scope and is noted for the guard follow-up, not recorded as an attack result.
- The review skill grades findings against the same threat model: a finding that needs write access to the repository is never blocking or major.
- The purpose text states the person's role (approve the specification at the start, accept or reject the result at the end, and decide at the remediation cap) and that the specification lock is lock and detect.

## Constraints
- Text only. No change under `lib/`, `exe/` or `test/`.
- Stacked on `change/process-speed` (pull request 63). It merges after that one.
- The wording proposed in `changes/process-speed/15-learning/proposed-rules.md` is the starting draft.
- Edits under `.ai/` need the maintainer's local guard override, as in process-speed.

## Non-goals
- The light track for the tool's own changes. It needs code and is the next stacked change, with the REV-004 and REV-005 fixes.
- Application-type paths (web app, API service, CLI or library) and the check catalog.
- Binding `rules` and `risk` to the intake commit, and any other guard work.
- Changing what any gate checks.

## Task classification
docs. The change edits documentation and skill instructions.

## Initial risk
low, chosen by the maintainer on 2026-11-14. Under the convergence rules a low risk change steps over discovery, threat modeling, planning, attack and learning by default and may promise at most 3 must criteria.

The attacker wording narrows what the attack and review phases report. That is a change that intentionally weakens a required control, so the maintainer's approval is recorded under `human_decisions` before the specification seals.
