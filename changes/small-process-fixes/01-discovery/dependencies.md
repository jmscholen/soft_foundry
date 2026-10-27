# Dependencies

## Internal dependencies
- `change new` depends on `ControlPlane` (tracks, default track), `ChangeRecord.create`, and the metadata template; callers of `ChangeRecord.create` in tests and harness evals must keep working when `type` and `risk` are not passed.
- Blocked-marking depends on `PhaseRunner#finish!`, `ChangeRecord#update_handoff` (record-locked write), and the gate's handling of `blocked`; `phase reopen` and `parallel_run.rb` also call `finish!`, so both run paths must behave alike.
- The latest-state summary depends on `Snapshot` (`state`, `skip_reason`, `recorded_cell`), `Gate#evaluate_all` if it reports live gate state, `Advisory` for what is owed, and `ChangeRecord` handoff readers.
- The parity rule depends on the existing `access_control` profile key (`ControlPlane#access_control`, `Declarations` syntax lint, `Scope` and `Check` staleness on edits), on `Sizing` for the same path-matching idea, and on `Gate::CHECKS` for a structure-only check.
- Skill and rule text is protected control-plane content: `check` lints it, the content scan reads it as instructions, and editing it after an evidence commit may stale evidence for open records.
- Harness evals (`soft-foundry eval`) run the shipped gate cases and `ci` runs them, so a new gate check needs a case or an existing one may change.

## External services and libraries
None added. Ruby standard library and the existing gems in `Gemfile.lock` only. No provider, network or credential is involved in any of the five fixes.

## Infrastructure dependencies
N/A. GitHub Actions CI (`.github/workflows/ci.yml`) runs the suite; no deployment target other than local gem builds (no RubyGems publishing).
