# Implementation Log

## Changes made
- RED `c8d5a66`: `test/code_quality_gate_test.rb`, 27 tests. All 27 failed or errored at that commit.
- GREEN (the commit that follows this log):
  - `.ai/workflow.yml`: the `quality` phase after `verify`, with `enabled_by: quality_gate` and `since_rules: 3`; a `quality` transition (`next: evaluate`, `on_blocking_findings: remediate`); `quality` added to `waivable_by_risk.low` and to the light track's optional phases (REQ-001, REQ-004, REQ-006).
  - `.ai/skills/code-quality/`: `SKILL.md`, `skill.yml` (commit-bound, prefers a provider other than implementation's), `permissions.yml` (writes only `06a-code-quality/`, may not read harness evals), `requirements.yml`, `completion.yml`, and seven templates: one per question and `consolidated.md` (REQ-002, REQ-003, REQ-007, REQ-008).
  - Other skills' `permissions.yml`: `06a-code-quality/**` added to the deny-write lists that enumerate phase directories, and to remediation's read list (REQ-003).
  - `lib/soft_foundry/control_plane.rb`: `Phase` carries `enabled_by` and `since_rules`.
  - `lib/soft_foundry/change_record.rb`: `asked_for?`, `not_asked_reason`, `run_phases`; `skippable?` and `skip_reason` use them; `phase_status` reads a missing directory as pending when the record is not asked for the phase; `change new` writes `rules: 3` (REQ-004, REQ-010, REQ-012).
  - `lib/soft_foundry/process_rules.rb`: `CURRENT = 3`; `VERSION` stays 2, so the convergence rules still apply to `rules: 2` records.
  - `lib/soft_foundry/gate.rb`: the `quality findings classed` check; the quality gate also carries `findings explained`, `fresh session recorded`, `remediation within cap` and `outside-change findings`; a missing handoff for a phase the record is not asked for reports `phase pending` with the reason (REQ-005, REQ-006, REQ-008, REQ-012).
  - `lib/soft_foundry/maturity_scan.rb`: `quality_gate` in the profile the scan writes, on for Ruby, Python, JavaScript, TypeScript or PHP, keeping a value a person set (REQ-004).
  - `lib/soft_foundry/advisory.rb`: the fresh-session advisory names the phase "code quality".
  - `lib/soft_foundry/cli.rb`: help text for `phase run quality` (REQ-010).
  - `.ai/templates/repository.yml`, `.ai/repository.yml`: the `quality_gate` setting; off in this repository by the maintainer's light-track decision.
  - `.ai/skills/review/SKILL.md`, `.ai/skills/final-judgment/SKILL.md` and its `template/evidence.yml`: review reads the phase's findings instead of repeating it; judgment lists the phase and records it as not run when it did not run (REQ-009).
  - `.ai/skills/remediation/SKILL.md`: the five steps for repairing a quality finding (REQ-014).
  - `.ai/rules/rails.md`: the four review decisions (REQ-013).
  - `README.md`, `.ai/README.md`, `AGENTS.md`, `.ai/schemas.md`, `docs/user/code-quality-review.md`, `docs/user/README.md`, and three mentions of `rules: 2` (REQ-010, REQ-011).
  - Existing tests: the assertions of the 14 tests that failed, in eight files (DEV-004).

## Test runs by this session
Provider keys and SOFT_FOUNDRY_PHASE unset.
- Full suite before the existing assertions were updated: 978 runs, 7216 assertions, 14 failures, 0 errors. All 14 were assertions that count or list phases, or state the rules number.
- After updating them, the twelve affected or related files were rerun one by one and pass (259 runs, 0 failures). The full suite was not rerun after that; verification runs it on the final commit.
- `soft-foundry check`: 17 phases, 18 skills, no errors. `soft-foundry ci` on this repository passed before the test updates.

## Decisions
See decisions.md.

## Deviations from plan
See deviations.md: DEV-001 to DEV-004.

## Challenges
- A bulk edit added the new directory after the first `06-verification` line of each `permissions.yml` whatever section it was in, which put it under `write:` for verification. It was reverted and redone per section.
- Running a shell command from inside a subdirectory made the guard's after-call hook write stray `.ai/` and `.soft-foundry/` folders there; they were deleted.

Files under `.ai/` were written under the maintainer's local warn override.
