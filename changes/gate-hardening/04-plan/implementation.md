# Implementation Plan

## Approach
One RED commit holding every new failing test, then GREEN commits in the order below, each leaving the suite closer to green and none editing a closed record. The gate work is additive (new check methods, new `CHECKS` entries, one tightened check); the sealing command is a new class the three existing run paths call. Fixture completion is done first because the new checks would otherwise fail every planted record and every test that completes a phase on disk, which would hide the real failures.

Decisions the specification left to the plan:
- **D1 (TM-001).** `phase seal` refuses when the checked-out branch is not the record's `metadata.git.branch`, unless that branch does not exist yet (first seal on a fresh record), in which case it proceeds and says so. Read as the only way REQ-001 ("commits that phase's directory") and REQ-033 ("of the named change") hold in a stacked workflow. Not a requirement change: it refuses a case the specification never permitted.
- **D2 (SPEC-002).** `HarnessEval#complete_phase!` becomes the one phase-completion fixture, exposed as `HarnessEval.complete_phase!(record, phase, sha, runner: true)`, and `test/test_helper.rb#complete_phase!` delegates to it. It writes values the new checks accept: `result: pass` and `criteria: [AC-001]` on the template check, one real evidence file with a correct manifest digest, `result: pass` on the template journey, `APPROVED` in `final.md`, and a runner-shaped `executed_by` for commit-bound phases. `HarnessEval#plant` commits once more after completing phases so each is recorded (REQ-006); the bound token stays the record commit, so lineage holds (each `commit_sha` equals its predecessor's).
- **D3.** New checks live in `gate.rb` as private methods, one per check, each rescuing its own reads into a `fail` (REQ-021). A `historical?` predicate (`status` closed or released) short-circuits each new check to `skip` (REQ-007).
- **D4.** The sealing command is `lib/soft_foundry/phase_seal.rb`, `PhaseSeal#call(phase) -> Result(outcome, sha, lines)` with outcomes `sealed`, `already_sealed`, `refused`, `gate_failed`, `commit_failed`; the CLI prints and maps to exit codes 0/0/1/2/2. The runner paths call the class, not the CLI.
- **D5.** Measuring tip for lineage and `branch_resolved`: `Scope.tip_for` gains a keyword `resolved:` (the handoff's `branch_resolved`, nil when absent) and returns nil (HEAD is the measure) when it is `false`. Callers pass it from the handoff.
- **D6.** Symlink refusal is one helper, `SoftFoundry::RecordFile.read(path)` (raises `RecordFileError` for a symlink, a non-regular file, or an unreadable file), used by `ChangeRecord#handoff`, `#metadata`, the new checks, and `ChangeSummary`.
- **D7.** `ps` reports every phase of a parallel run joined by `,` in its existing phase field; no new field.

## Application changes
In GREEN order. Paths under `lib/soft_foundry/` unless stated.

1. **Fixture completion** (D2): `harness_eval.rb` (`complete_phase!` phase-aware; `plant` commits after completion), `test/test_helper.rb` (delegate). Covers nothing on its own; makes everything after testable.
2. **Record file guard** (D6): new `record_file.rb`; `change_record.rb` (`handoff`, `metadata`, `recorded_branch` accessor returning a typed error for a non-mapping `git`); `change_summary.rb` uses it and prints the malformed-field lines (REQ-019, REQ-034, REQ-021 part).
3. **Gate checks** (REQ-007 to REQ-014, REQ-006, REQ-021): `gate.rb`
   - `CHECKS` entries for the seven new names; `checks_for` ordering: after `required files present` → `structured files parse`; after `commit_sha recorded` → `commit lineage`; after `predecessor complete`; verify: `test results recorded`, `criteria covered`; verify/evaluate/attack: `evidence manifest verified`; judge: `criteria covered`, `verdict recorded`; review/judge: `fresh session recorded`.
   - `predecessor_check`: `prev_status == "complete" && recorded_commit(prev)`; detail names `soft-foundry phase seal <prev id>`; no git repository → status-only as today.
   - `structured_files_check`, `lineage_check` (predecessor SHA → this SHA → tip), `test_results_check`, `criteria_coverage_check(level)`, `manifest_check`, `verdict_check` (via `judgment_outcome`), `fresh_session_check` (reads `.ai/policies/enforcement.yml` through `ControlPlane`, never the override).
   - `staleness_check` and `lineage_check` read `git.branch` through `recorded_branch`; a non-mapping becomes a `fail` line.
   - `Text.blank?` (new, in `text.rb`) for Unicode-blank reasons; `ChangeRecord.discharged?` uses it (REQ-022).
4. **Sealing** (REQ-001 to REQ-005, REQ-020, REQ-033, D1, D4, D5): new `phase_seal.rb`; `cli.rb` `phase seal` subcommand and usage; `PHASE_USAGE`; single-run path (after `mark_blocked`, before the exit), parallel path (replace the `first_open` metadata write with ordered sealing; keep the `moved` check before sealing), panel path (seal after an agreed outcome passes the gate); `phase_runner.rb` prompt step 5 and the parallel sentence; `scope.rb` `tip_for(resolved:)`; `PhaseSeal` writes `branch_resolved` for commit-bound phases before the gate runs so the gate measures what will be committed.
5. **Commands** (REQ-016 to REQ-019, REQ-022, REQ-023): `cli.rb` `gate` exit 3; `change_close` verdict refusal; `option` equals form and the twice refusal (`options` collects through a private `take_option` that does not raise on repeats); `phase_reopen.rb` `started_at`; `processes.rb` `phase_of`; `check.rb` `check_vocabulary` forced_by_risk; the `warn:` line at `cli.rb:1160`; parallel exit 2 on a session-authored `blocked`.
6. **Suite isolation** (REQ-024): `test/test_helper.rb#cli` runs under `with_env` clearing `SOFT_FOUNDRY_PHASE`, `SOFT_FOUNDRY_PARALLEL`, `SOFT_FOUNDRY_GUARD`, and the provider keys; `LifecycleFixture#with_clean_env` reuses the same list.
7. **Text the implementation skill may not write** (REQ-015, REQ-026, REQ-028, REQ-030; landed under the maintainer's warn-mode override and recorded in `deviations.md`): `.ai/skills/verification/template/tests.yml`, `final-judgment/template/evidence.yml`, `.ai/templates/handoff.yml`, `.ai/skills/*/SKILL.md` lines that say how a phase ends, `AGENTS.md` step 9, `README.md` sections, `.ai/harness-evals/cases/` (seven new gate cases plus the three owed), `.ai/rules/learned.md` via `soft-foundry learn promote`. `docs/user/` pages are the documentation phase's (REQ-029).

## Database changes
N/A.

## Infrastructure changes
N/A. No CI change; the hook and Actions run what they run today.

## Test strategy
See `testing.md`. One RED commit with every new test file; `tests.yml` names it on each check with `test_path`. Suite run twice at the verification commit: with keys and `SOFT_FOUNDRY_PHASE` unset (the record run) and with `SOFT_FOUNDRY_PHASE=verify` and a provider key set (AC-048). `soft-foundry check`, `eval`, and `ci` at the same commit.

## Rollout
See `rollout.md`. Local gem build and install after merge; adopters receive it through `soft-foundry update`. In-flight adopter records with a phase complete on disk but uncommitted will fail the next gate's `predecessor complete` with the sealing command named; that is the intended first contact.

## Rollback
See `rollback.md`. Revert the merge; records sealed by the new command are ordinary commits the old gate reads; the two new optional keys are ignored by it.

## Risks
- **Fixture breadth** (DISC-007, SPEC-002): tests that gate a later phase after on-disk completion may be many; D2 puts the fix in one helper, and the RED run reports the count. Mitigation: do step 1 first and run the suite before writing any check.
- **Strictness on this change's own record:** every check this change adds applies to its own verification, evaluation, attack, review and judgment. That is the point; the evidence phases must write `result`, manifests, `criteria`, and run through `phase run`.
- **Hook time:** sixteen seals × `ci`. Measured at evaluation (AC-052); a slow hook is a follow-up, not a reason to pass `--no-verify`.
- **D1 and stacked changes:** refusing a seal from the wrong branch must not refuse the ordinary case where the record's branch is checked out under a different worktree path. The check compares branch names, not paths.
- **Alias-expansion YAML** (THREAT-010): bounded by the fixed parsed set; ATTACK-012 records the measurement.
