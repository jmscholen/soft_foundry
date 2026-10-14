# Implementation Plan

## Approach
Test first, in small RED/GREEN pairs, one requirement group at a time, each GREEN commit naming the requirement. New behaviour lives in existing modules where it belongs (`Gate`, `Advisory`, `Guard`, `Check`, `CLI`) and in one new module, `HarnessEval`, that reuses the test suite's scratch-repository pattern in library code so an installed gem can run it. Control-plane and documentation edits come last, before the guard mode flips, because the implementation skill cannot write them and block mode would refuse them; each is recorded as a deviation.

Order:
1. **REQ-FR-001 UTF-8.** `SoftFoundry.read_text(path)` (a module function): `File.binread(path).force_encoding("UTF-8").scrub`. Replace every content `File.read` in `lib/` with it (gate, advisory, learning, maturity scan, change record templates, snapshot, UI server asset reads, panel, content scan's `binread` stays). `test/ui_assets_test.rb` reads with it too. Test: a record file with a UTF-8 arrow under `Encoding.default_external = US_ASCII` passes the placeholder check; a file with an invalid byte is scrubbed, not raised.
2. **REQ-FR-002 lock.** `Gate#specification_lock_check` takes the lock commit from `vetted` when present, else from the specify handoff's `commit_sha` when specify is complete (and the change is not exploring); `checks_for` lists it for specify on every track. `staleness_check` adds `changes/<slug>/02-specification/**` to the compared globs with its own wording. Tests: AC-FR-003, 004, 005.
3. **REQ-FR-003 advisory.** `Advisory#fresh_context_notices` iterates every phase whose skill is `commit_bound?`. The three SKILL.md files gain one sentence. Test: AC-FR-006.
4. **REQ-FR-007 waivers.** `ControlPlane#waivable_by_risk` (from `workflow.yml`), `Gate#waivers_check` on the first phase, `Check#check_waivers`, `CLI#change_close` judgment refusal. The shipped `workflow.yml` gains the rule. Existing tests that waive judge or review in fixtures move to a low-risk waiver of allowed phases or complete the phases. Tests: AC-FR-016, 017, 018.
5. **REQ-FR-004 block mode and MIT-001.** `Guard::SELF_PROTECTED` paths refused in every skill for write tools and shell mentions; `.ai/policies/enforcement.yml` set to `block`; the refusal line mentions the override's existence; `hooks install` already prints the mode. Tests that assumed warn set `SOFT_FOUNDRY_GUARD=warn` explicitly. Tests: AC-FR-007, 008; ATTACK-001.
6. **REQ-FR-005/006 harness evals.** `lib/soft_foundry/harness_eval.rb`: `Case` (load, validate), `Runner` (scratch repo, scaffold, apply, gate, compare; live: `phase run` through `CLI` in-process with the scratch root), `Result`; `CLI#eval` and help; `ci` runs gate cases; `Check#check_harness_evals`. Ten shipped cases under `.ai/harness-evals/cases/` and a README. Tests: AC-FR-009..014 with a fake shell for live.
7. **REQ-FR-008 application repository.** `test/application_repo_test.rb` builds the Rails-shaped fixture and runs the journey in-process (RED from the start: `eval` does not exist and block mode is not installed; GREEN once 5 and 6 land).
8. **REQ-FR-010 docs and version.** README, help, `.ai/schemas.md`, `.ai/README.md`, `AGENTS.md`, `.ai/harness-evals/README.md`, `version.rb` 0.21.0.

## Application changes
- `lib/soft_foundry.rb`: `read_text`.
- `lib/soft_foundry/gate.rb`: lock on gated track; staleness on specification; `waivers permitted`; UTF-8 reads.
- `lib/soft_foundry/advisory.rb`: fresh-context notices for every commit-bound phase; UTF-8 reads.
- `lib/soft_foundry/control_plane.rb`: `waivable_by_risk`, `commit_bound_phases`.
- `lib/soft_foundry/change_record.rb`: `waivable?(phase)`; `reached_lifecycle_end?` unchanged in shape but judge is never skippable.
- `lib/soft_foundry/guard.rb`: `SELF_PROTECTED`; block-mode message.
- `lib/soft_foundry/check.rb`: `check_waivers`, `check_harness_evals`.
- `lib/soft_foundry/harness_eval.rb` (new).
- `lib/soft_foundry/cli.rb`: `eval`, `ci`, `change close`, help.
- `lib/soft_foundry/version.rb`: 0.21.0.
- Control plane: `.ai/policies/enforcement.yml`, `.ai/workflow.yml`, three SKILL.md, `.ai/harness-evals/**`, `.ai/schemas.md`, `.ai/README.md`; `AGENTS.md`; `README.md`.

## Database changes
N/A.

## Infrastructure changes
N/A. CI runs `rake ci`, which gains the deterministic evals through `ci`.

## Test strategy
See `testing.md`. Every group has a RED commit holding only its failing tests, then a GREEN commit; verification names each RED commit on the check that covers it.

## Rollout
See `rollout.md`.

## Rollback
See `rollback.md`.
