# Architecture Review

## Scope reviewed

`PhaseProvider`, `PhaseRunner#default_shell`, `CLI#phase`, `Advisory#same_provider_notices`, `Gate#findings_explained_check`, and `Check#check_skill_contract`, against `.ai/rules/architecture.md` and `.ai/rules/general.md`. The diff from `4c777bd` to HEAD, excluding `changes/`, is the twenty-one files in the implementation log: the two skill declarations, the review skill text and seven templates, the handoff template, `.ai/schemas.md`, README, six library files, the version, and one test file.

## Findings

None.

## Decisions checked

The preference lives on the review and final-judgment skills, not on the shared `reasoning_high` profile. Profiles are shared; putting it on the skill is the decision in `05-implementation/decisions.md`, and it matches REQ-XP-001.

`PhaseProvider` is a module with no dependency on the runner, the gate, or the advisory. `PhaseRunner.provider_of` delegates to it. That split is what breaks the load cycle the implementation log describes (advisory, runner, gate, change record). It is a small module for a demonstrated cycle, which `.ai/rules/architecture.md` allows.

Provider resolution has one implementation. The runner and the advisory both call it, so a name that means anthropic to the default also means anthropic to the notice.

## Deviation

Implementation wrote `.ai/` and `README.md`, which are outside that skill's write set. REQ-XP-001, REQ-XP-005, REQ-XP-006, and REQ-XP-007 name those files, and no skill's write set covers them. The diff is only those edits plus the library, the test, and the version. `05-implementation/deviations.md` records it and asks review to approve it. Approved. The maintainer still accepts the control-plane edits at merge, as that deviation says.

## Conformance

Conforms. The new code follows the existing runner, gate, and advisory boundaries. No cyclic dependency was reintroduced. The control-plane writes are an approved deviation, not an unrecorded one.
