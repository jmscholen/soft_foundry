# Implementation Plan

## Approach
Add one small module, `lib/soft_foundry/process_rules.rb`, that answers every question the new rules ask of a record: whether the rules apply (rules version), the remediation round count and allowance, the must cap for a risk, the must set, decisions by boundary, default waivers, and whether a path is documentation. `PhaseReopen`, `PhaseSeal`, `Gate`, `Sizing`, `Release` and `ChangeRecord#skippable?` call it; none of them duplicates the logic. Every new check returns skip with "legacy record" when the rules do not apply, and uses the existing `HISTORICAL` skip for closed and released records.

Order, each step RED (a failing test committed first) then GREEN:
1. ProcessRules core: rules version, workflow keys and their lint, docs-path test, decision lookup. Template `.ai/templates/change/metadata.yml` gains `rules: 2` (REQ-001).
2. Round count and cap at reopen and seal, parking, and the review/judge cap check (REQ-002, REQ-003; MIT-002, MIT-003, MIT-009, MIT-010).
3. Tiers, must cap and approval checks at specify; tier-aware criteria check at judgment (REQ-004 to REQ-006; MIT-005).
4. person_checks into `change release` (REQ-007).
5. Blocked basis at judgment; outside_change findings at review and attack (REQ-008, REQ-009; MIT-006).
6. Rules version kept since intake (MIT-007).
7. Default low-risk waivers; documentation-only sizing (REQ-010, REQ-011; MIT-008).
8. Documentation-only reopen and its seal refusal (REQ-012; MIT-004).
9. Skill text, schemas, README, user documentation, harness-eval cases (REQ-013, REQ-014).
10. Full suite and `soft-foundry ci` (REQ-015).

## Application changes
- `process_rules.rb` (new): `applies?(record)`; `remediation_rounds(record, git)` = max(count of `Record <slug> remediate` commits reachable from the record's branch tip or HEAD, count from phase_reopenings entries whose previous remediate status was complete plus one if remediate is complete now); `round_allowed?(record, git)` = rounds < limit, or a "remediation cap" decision with `rounds` equal to the current count and decision accept_residual or narrow; reject never allows; `must_cap(plane, risk)`; `must_ids(record)`; `decisions(record, boundary)`; `default_waived(record, plane)`; `documentation_path?(path, slug)` = DOCS group, `*.md` at the root, or `changes/<slug>/**`, never `.ai/**`.
- `control_plane.rb`: readers for `remediation.max_rounds`, `must_criteria_cap`, `default_waivers` in workflow.yml; fail closed (TargetError naming the key) when malformed.
- `check.rb`: lint the three keys (integers 1 or more; a cap per declared risk; default_waivers names only risks in waivable_by_risk).
- `phase_reopen.rb`: when the reset would include remediate and `round_allowed?` is false, inside the existing lock and transaction write only `status: awaiting_human` and raise TargetError with the refusal text (boundary name, the three decisions, the rounds field). `--docs-only` (manual only; a phase-run session is already refused): reset remediate plus document, index, observe, review, judge, learn; keep verify, evaluate, attack; record `docs_only: true`.
- `phase_seal.rb` `refusal`: sealing remediate when the seal would exceed the allowance parks and refuses the same way; when the latest remediate reopen entry has `docs_only`, refuse if any path changed between its from_commit and HEAD fails `documentation_path?`, naming the first paths and telling the person to reopen without `--docs-only`.
- `phase_runner.rb`: the automatic reopen of a stale remediate goes through PhaseReopen and therefore the same refusal; the runner prints it and starts no session (AC-003).
- `gate.rb`: new checks, each in `CHECKS`:
  - `rules kept` (first phase): fails when the intake sealing commit's metadata declares `rules` and the current metadata does not.
  - `criteria tiered` (specify): every criterion has tier must or should; the must count is within the cap for the declared risk.
  - `must criteria approved` (specify): a "must criteria approval" decision whose criteria set equals the must set, decision approved.
  - `remediation within cap` (review, judge): rounds above the limit are each answered by a decision.
  - `blocked basis` (judge): BLOCKED requires evidence.yml `blocked_by`, each an unmet must criterion id or a review finding id with severity blocking, a failure, and no outside_change.
  - `outside-change findings` (review, attack): a finding with `outside_change: true` has a follow_up and paths, and none of its paths changed in the change's diff (Scope measure from the plan's diff base).
  - `criteria covered` changes on new-rules records: at judgment only must criteria fail when uncovered; should criteria warn.
- `change_record.rb` `skippable?`: also true for a default waiver (`default_waived`) unless named under `run_phases`. `waivers_check` reports "default waivers: …".
- `sizing.rb`: before the scope rule, when every measured path is documentation, return the smaller size with the reason "documentation-only diff".
- `release.rb`: `change release` appends one item per person check not already named by `--item` (`from: person_check`).
- `advisory.rb`: a follow-up advisory per outside_change finding; a parked-on-cap advisory naming the boundary.
- `cli.rb`: `phase reopen --docs-only`; help text; messages per REQ-016.

## Database changes
N/A.

## Infrastructure changes
N/A.

## Test strategy
See testing.md. New `test/process_speed_test.rb` (unit and fixture-level gate tests) and `test/cli_process_speed_test.rb` (command-level), using `lifecycle_fixture.rb` with a `rules: 2` option. Targeted runs during implementation; the full suite (about 18 minutes, DISC-001) with provider keys and SOFT_FOUNDRY_PHASE unset before verification.

## Rollout
See rollout.md.

## Rollback
See rollback.md.

## Control-plane text
Edits under `.ai/workflow.yml`, `.ai/policies/human-boundaries.yml`, `.ai/policies/check-sizing.yml` (comment for the documentation-only rule), `.ai/skills/*/SKILL.md`, `.ai/templates/`, `.ai/schemas.md`, `.ai/harness-evals/cases/` and `README.md` are outside implementation's write set. They are written under the maintainer's documented warn-mode override and listed in the implementation handoff, as on gate-hardening. The maintainer sets and removes the override.

## Risks
- The round count disagrees with intuition on records with manual verify reopens (readme-workflow-visuals has one); the worked example is a test.
- The documentation-only definition is too narrow (a CHANGELOG under a subfolder) or too wide; it is one function with tests.
- The must cap is too low for real high-risk work; the value is policy in workflow.yml, changed without code.
- TM-001 (shell-written decisions) stays residual.
