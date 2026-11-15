# Change Intake

## User intent
On 2026-11-14 the maintainer decided that Soft Foundry's own changes go on a light track: specification, implementation, the test suite, one review. The full lifecycle is for applications built with it. The maintainer also agreed to carry two defects from process-speed's review (REV-004, REV-005) into this change, and the time budget is 1 to 3 hours for a medium-risk feature.

purpose-and-scope then showed where the time goes on a small change: verification ran the 21-minute suite twice on four text files, because the change declared no scope.

## Desired outcome
- A third lifecycle track, `light`, that a change can be created on (`soft-foundry change new <slug> --track light`). On it the required phases are intake, specify, implement, verify, review and judge. Every other phase is optional: the gate does not ask for it and `phase seal` steps over it.
- The light track keeps the specification lock, the must-criteria approval, the remediation cap, review and judgment. It removes phases; it does not remove locks.
- A high-risk change cannot use it (the existing `forced_by_risk` rule sends high risk to the gated track).
- REV-004 fixed: paths in an outside-change finding are normalized before they are compared with the change's modified paths, so `./lib/app.rb` matches `lib/app.rb`. Absolute paths and globs are refused.
- REV-005 fixed: a remediation that was reopened before it completed is not counted as a round, and the cap message describes what was counted.
- Verification of a change whose diff touches only documentation and the change record is not sized as a full suite run.
- Two wording fixes from purpose-and-scope's judgment: the review skill separates "could be edited" from "was seen to be edited" (R-1), and the attack skill no longer says the guard and the lock cover repository-write tampering outright (R-2).

## Constraints
- The gated and iterative tracks behave exactly as they do today.
- Records that already exist are not affected.
- Evidence phases run with `--shell claude` (maintainer, 2026-11-14).
- Edits under `.ai/` and to `metadata.yml` need the maintainer's local guard override.

## Non-goals
- Application-type paths (web app, API service, CLI or library) and the check catalog.
- Guard work: redirections, the working-directory root, the restore step, binding `rules` and `risk` to the intake commit.
- Making light the default track of this repository. The default stays gated; a change opts in.
- Parallel test runs and reuse of a recorded suite result.

## Task classification
feature. A new track in the tool, two defect fixes, one sizing rule, two wording fixes.

## Initial risk
low, following the maintainer's decision that the tool's own changes run light. The change removes required phases for changes that opt in, which intentionally weakens a required control; the maintainer's approval is recorded under `human_decisions` before the specification seals.
