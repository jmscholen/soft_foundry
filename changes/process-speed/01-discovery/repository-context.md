# Repository Context

Discovered at 623a98c (main 3fd048c plus the intake seal), worktree `.claude/worktrees/process-speed`.

## Discovered
- **Architecture.** A Ruby gem (`soft_foundry` 0.23.0) with one executable, `exe/soft-foundry`, dispatching through `lib/soft_foundry/cli.rb`. The lifecycle is declared in `.ai/workflow.yml` and read by `ControlPlane`; a change record is read and written by `ChangeRecord`; `Gate` (`gate.rb`, 847 lines) evaluates one phase's handoff with structural checks named in `Gate::CHECKS`; `PhaseSeal` gates and commits a phase and advances `current_phase`; `PhaseReopen` resets a phase and its downstream to pending and appends `phase_reopenings`; `PhaseRunner` runs a phase in a fresh session and reopens a stale complete phase automatically (source `auto`); `Sizing` computes check sizes from the diff, the record's `scope` and `.ai/policies/check-sizing.yml`; `Advisory` prints go-live advisories; `Release` handles `change release` and `change discharge`.
- **How a remediation round happens today.** Nothing in code routes a change to remediation. Review's `on_blocking_findings` and judgment's `on_blocked` in `workflow.yml` `transitions` are read only by `check` (lint) and `ControlPlane#downstream`; the agent follows them by running `soft-foundry phase reopen remediate --reason TEXT` by hand. `PhaseReopen` resets remediate plus everything `downstream` returns: every later lifecycle phase plus remediate's `next` edge (verify) and its successors, so verify, evaluate, attack, document, index, observe, review, judge and learn. Each round is therefore one `phase_reopenings` entry whose `reset` includes `remediate`, followed by a `Record <slug> remediate` seal commit. A first remediation can also start without a reopen (remediate is reached while still pending).
- **Parking.** `status: awaiting_human` exists: `PhaseReopen` and `Release` refuse while a record is parked, `change summary` and the UI snapshot report it, and the panel runner in `cli.rb` sets it on a split. Nothing un-parks a record in code: a person edits `status` and records `human_decisions`. `Advisory#human_decisions(boundary)` filters entries by boundary name; only `legal commitment` and `panel split` are read today.
- **Acceptance criteria in code.** `Gate#acceptance_ids` reads ids from `02-specification/acceptance-criteria.yml`; `criteria_check` (verify: warn, judge: fail) requires every id to be named by a `tests.yml` check's `criteria`, an evaluation journey's `criteria`, or `14-judgment/evidence.yml criteria_not_covered` with a two-word reason. No other field of a criterion is read. There is no tier and no count limit.
- **Judgment in code.** `verdict_check` requires exactly one permitted outcome in `final.md`; nothing ties BLOCKED to a reason. `findings_explained_check` requires `failure:` on review findings above minor; severity words are otherwise unread.
- **Staleness.** `evidence current` fails only when application, test or infrastructure code (APP `lib/**`, `exe/**`; TESTS `test/**`; INFRA) changed after the evidence commit, or the specification was re-recorded. A change to `README.md`, `docs/**` or the record does not stale evidence. The whole-tail rerun after a wording fix is caused by `PhaseReopen`'s downstream reset, not by staleness.
- **Sizing.** With `scope: []` every size is the larger one ("no scope declared"). evaluate and attack also need `access_control` globs, which this repository does not declare, so they are always `full_route_sweep` here. Nothing distinguishes a documentation-only diff.
- **Waivers.** `waivers_check` validates `skipped_phases` against `waivable_by_risk`; `ChangeRecord#skippable?` steps over a phase that is optional, waived with a rationale, or track-optional. A waiver exists only when someone writes it; `change new` writes `skipped_phases: []`.
- **Human boundaries.** `.ai/policies/human-boundaries.yml` is a list of prose strings; code matches boundary names only in `human_decisions` entries (`boundary:`).
- **Skills.** `final-judgment/SKILL.md` and `remediation/SKILL.md` are two lines each. `specification/requirements.yml` requires functional, acceptance, accessibility, security, failure, observability and traceable-id coverage for every change. `review/SKILL.md` already states the "a reviewer will always find something" threshold for findings.
- **Runtime.** Ruby 3.3.1 under asdf; `bundle exec rake test` (minitest) and `soft-foundry ci` (control-plane lint, harness gate evals, every record's gate). No network service, database or deployed infrastructure.
- **Tests.** `test/` holds about 80 minitest files; directly relevant: `gate_checks_test.rb`, `gate_test.rb`, `cli_phase_reopen_test.rb`, `control_plane_downstream_test.rb`, `lifecycle_tracks_test.rb`, `cli_change_release_test.rb`, `harness_eval_test.rb`, `lifecycle_fixture.rb`. Harness-eval gate cases live under `.ai/harness-evals/cases/`; discovery is denied reading them by design.
- **Auth boundaries.** No user authentication. The control boundary is separation of duties: per-skill `permissions.yml`, the PreToolUse guard (`guard.rb`, block mode per `.ai/policies/enforcement.yml`), `SOFT_FOUNDRY_PHASE` marking a phase-run session, and the protected `.ai/policies/**` and harness evals. `PhaseReopen` refuses inside a phase-run session so a phase cannot reset another phase.

## Inferred
- The round cap is enforceable at one point: `PhaseReopen#reopen` when the reset includes remediate, plus the remediate seal for a first round reached without a reopen. Counting from `phase_reopenings` is record state the tool already writes; counting `Record <slug> remediate` commits is a git fact. Either is structural.
- A lighter rerun after a documentation-only remediation is a change to which phases `PhaseReopen` resets (or which `advance!` treats as still current), decided from the diff since the last evidence seal with the same path groups staleness uses.
- Tiers and the must-list approval fit existing patterns: a field in `acceptance-criteria.yml` read by `Gate`, and a `human_decisions` entry with a new boundary name read the way `legal commitment` is.

## Defined by repository policy
- Gate checks are structural and never judge truth (`Gate::CHECKS` wording; README).
- Closed and released records are not re-gated by later checks (`Gate::HISTORICAL`).
- `.ai/policies/**` is protected from every skill's write set; changes to it are written under the maintainer's warn-mode override and recorded, as on gate-hardening.
- Review and judgment are never waived (`ControlPlane::NEVER_WAIVED`, `check`).

## Published policies
Unchanged and mirrored in `.ai/repository.yml` `policies:`: privacy NOT_APPLICABLE (library gem, no user data), security NOT_APPLICABLE (maintainer decision 2026-09-15, changes/security-policy-not-applicable), terms NOT_APPLICABLE (no service offered). This change alters none of them; `surfaces.policy: false`.

## Unknown
See unknowns.md.

## Affected components
See affected-components.md.

## Dependencies
See dependencies.md.
