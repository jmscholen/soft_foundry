# Implementation Log

## Changes made
- `.ai/workflow.yml`: a `tracks:` block (`default: gated`; `gated`; `iterative` with `exploring: true`, `skill: exploration`, `output: exploration`, `vet_requires: [intake, specify]`, `optional: [discover, threat_model, plan]`; `forced_by_risk: {high: gated}`), with a comment explaining both tracks and the exploring rule.
- `.ai/skills/exploration/` (new stage skill): `skill.yml` (`stage: exploring`, coding_high, the implementation rules), `SKILL.md`, `permissions.yml` (implementation's write set plus `02-specification/**` and `exploration/**`; denies every evidence directory), `requirements.yml`, `completion.yml` (checked by `change vet`), `template/iterations.yml`.
- `.ai/templates/change/metadata.yml`: `track: ${TRACK}`, `status: ${STATUS}`, `current_phase: ${CURRENT_PHASE}`, `exploring` in the status comment, `vetted: null` and `reopenings: []` with commented examples. `.ai/templates/repository.yml`: an `environments:` block. `.ai/repository.yml`: this repository's `development` environment (a local checkout against a scratch repository) and updated findings for `governance.risk_classification` and `change.acceptance_criteria_locking`. `.ai/policies/human-boundaries.yml`: deploying anywhere other than development. `.ai/maturity.yml`: an assessment rule that either track satisfies the lifecycle capabilities and where locking is deterministic.
- `lib/soft_foundry/control_plane.rb`: `Track`, `tracks` (implicit `gated` when none declared), `track`, `track_names`, `default_track`, `track_forced_by_risk`, `hardening_phase?`.
- `lib/soft_foundry/check.rb`: `check_tracks` and `check_exploring_writes`; `check_phase` refactored onto a shared `check_skill_contract` so the stage skill is linted with the same rules minus the handoff requirement.
- `lib/soft_foundry/change_record.rb`: `create(track:)`, scaffold writes `TRACK`/`STATUS`/`CURRENT_PHASE` and copies the stage templates into `exploration/`; `track`, `track_definition`, `exploring?`, `vetted`, `exploration_dir`, `iterations_path`, `iterations`, `skipped_with_rationale`, `skippable?` (now also used by `reached_lifecycle_end?`); `vet!`; `reopen!`.
- `lib/soft_foundry/gate.rb`: `track_check` on the first phase, `exploring_check` on complete hardening phases while exploring, `specification_lock_check` on a vetted change's specification, predecessor check via `record.skippable?`.
- `lib/soft_foundry/cli.rb`: `change new --track`, `change vet`, `change reopen`, `track_line` in `change new` and `change status`, help text. `lib/soft_foundry/git.rb`: `user_name`. `lib/soft_foundry/advisory.rb`: `environment_notices`.
- `AGENTS.md` (steps 3 and 4), `README.md` ("Lifecycle tracks: gated or iterative"), `.ai/README.md`, `.ai/schemas.md` (metadata fields, three gate checks, the advisory).
- Tests: `test/lifecycle_tracks_test.rb` (25 tests: tracks parsing and the implicit track, `check` on a bad default, unknown phases, an evidence-writing stage skill, and a missing contract file; `change new` on both tracks and an unknown one; `ci` and `status` while exploring; the `not exploring`, `track permitted`, and `specification locked` checks; every `vet` refusal and its effects including the git identity default; `reopen` effects and refusals; lifecycle end and `close` for an iterative change; the environment advisory on both tracks).
- Version bumped to 0.9.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- The gate checker itself never blocked iteration: in-progress and pending phases already passed `ci`. What blocked it was the contract (phase order, a locked specification, every edit invalidating five phases). So the change is mostly to what the record is allowed to say and when, and only three gate checks are new.
- "Produces no evidence" is only true if something checks it. Declaring the stage skill's write set and then linting that it cannot reach a commit-bound directory turned a design principle into a `check` error.
- A person's acceptance has to be a commit, not a state: locking the specification at `vetted.commit` gave the iterative track the deterministic acceptance-criteria lock the maturity model has been recording as PARTIAL since discovery, without changing how the gated track writes records.
- The evaluation script's first run showed a `check` that "passed" where it should have failed: the appended permission had landed under `deny_write`, not `write`. The transcript was regenerated after fixing the script rather than annotated, because a transcript that shows the wrong thing is not evidence.

## Challenges
None substantive. The first evaluation run had two script errors (a permission appended to the wrong list; `git revert -q` is not a flag), both in the harness for the journeys and neither in the change; the script was corrected and rerun in full.
