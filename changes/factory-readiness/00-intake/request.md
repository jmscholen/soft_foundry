# Change Intake

## User intent
The maintainer asked for an assessment of whether this repository is state of the art in autonomous software development, then said: "Go ahead and do what you recommend. I want this to get to a finished and predictable state to run on application repos and feel confident that I have an autonomous software factory."

The assessment (this session, 2026-10-14, against `main` at 6bf2127 and the then-open #48) found the governance design ahead of the field and the enforcement, measurement, and external proof behind it:

1. The judgment gate has never said no: all 30 closed records are APPROVED or APPROVED_WITH_RESIDUAL_RISK, and nothing has ever planted a bad change to see whether the pipeline catches it. `.ai/harness-evals/` is one README; every record's `15-learning/proposed-evals.md` is never executed. Level 6 of `.ai/maturity.yml` is entirely MISSING.
2. Verification, evaluation, and attack run in the implementing session in every record, including the newest; only review and judgment have a fresh-context path (`phase run`) and an advisory when it was not used.
3. The guard defaults to `warn`, so a permission violation is reported and allowed.
4. On the gated track the specification is not locked: `change.acceptance_criteria_locking` is PARTIAL because the gate detects edits to `02-specification/` only after `change vet` on the iterative track.
5. The suite has 5 errors under a C locale (`invalid byte sequence in US-ASCII` in `Gate#placeholder_check` and `test/ui_assets_test.rb`); CI passes only because `ubuntu-latest` is UTF-8.
6. The lifecycle has only ever governed this repository. No record shows it applied to an application repository (the maintainer's target is Rails), so the product thesis is unproven outside the tool.
7. `.ai/repository.yml` still scores maturity level 2 from an assessment on 2026-09-09 that predates most of the capabilities, with findings such as "no judgment has run yet" that are no longer true.

The maintainer merged #48 (panel mode, 0.20.0) to `main` at 0bd0260 at the start of this change, on the session's recommendation.

## Desired outcome
Soft Foundry at a version an application repository can install and rely on, with each of the seven findings above closed or honestly bounded:

- An executable harness-eval suite under `.ai/harness-evals/` and a `soft-foundry eval` command that runs it: deterministic cases plant a defective change record and assert which gate check refuses it (plus a well-formed control that must pass), and live cases plant a defect in a fixture application and run a fresh-context review through `phase run` to assert the reviewer finds it. `ci` runs the deterministic cases; the live cases run on request with a named shell. The suite ships with the control plane so an application repository can prove its installed gate still catches planted defects.
- The fresh-context advisory covers every commit-bound evidence phase (verification, evaluation, attack, review, judgment), not only review and judgment, so a record whose evidence was produced by the implementing session says so on every gate run.
- The guard's repository policy is `block`, so a permission violation is refused rather than reported; the machine-local override and the environment variable remain the documented way round it.
- The specification is locked on the gated track from the commit the specify phase completed at: the gate's `specification locked` check fails on any later edit under `02-specification/`, and commit-bound evidence produced before a specification change is stale.
- Every file the tool reads is decoded as UTF-8 regardless of the process locale; the suite passes under `LANG=C`.
- The lifecycle is exercised end to end against a Rails-shaped application repository (install, assess, open a change, guard decisions, gate, eval), as a regression test and as a recorded evaluation journey, and whatever that exposes is fixed in this change.
- `.ai/repository.yml` is brought current by this change's discovery phase: stale findings replaced with evidence, maturity rescored by the tool's own rule.
- README, help text, and `.ai/schemas.md` describe all of the above. Version 0.21.0.

## Constraints
- Every change to this repository goes through its own lifecycle (`AGENTS.md`). This change runs every phase: the assessment faulted the habit of skipping discover, specify, threat_model, and plan, so this record does not skip them.
- Verification, evaluation, attack, review, and judgment are to run through `soft-foundry phase run` in fresh sessions where the environment allows it (the `claude` shell is installed and answers headless prompts here; `codex` and `grok` are not installed), and the handoffs say what actually happened.
- The gate stays a structure check. Harness evals assert what the gate and a reviewer do with planted inputs; they do not change what the gate requires.
- No skill may write `.ai/harness-evals/`, `.ai/policies/`, or `README.md`. The edits this change needs there are recorded as deviations, as prior records did, and are the maintainer's to accept at merge.
- Nothing in the evidence contains a real credential; planted secrets are canary shapes and the transcripts mask them.
- Every new output line carries a status word (`.ai/rules/accessibility.md`).

## Non-goals
- An OS-level sandbox for agent sessions (containers, network egress policy). The panel-phases judgment accepted that residual risk; this change does not reopen it.
- Live model metering of spend (the budget stays a ledger).
- Provider or model routing from the capability profiles (`.ai/runtime/models.yml` stays declarative).
- Running the live harness evals on `codex` or `grok` in this session: neither is installed here.
- Guarding against a stacked pull request merged into the wrong base branch (the #47/#48 mishap); recorded for a later change.
- Reopening or re-scoring any closed record.

## Task classification
Feature: a new command and its data format under `.ai/`, two gate behaviors, an advisory, a policy default, an encoding fix, a new end-to-end test, a discovery update, documentation, and a version bump.

## Initial risk
medium. The guard default and the specification lock change what every future change in every onboarded repository is held to; the eval suite ships to application repositories; nothing touches a deployed service or a person's data.
