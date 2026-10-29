# Dependencies

## Internal dependencies
- `Gate` depends on `ChangeRecord` (handoffs, `recorded_commit`, `judgment_outcome`, `phase_status`), `ControlPlane` (phases, skills, `code_globs`, `effective_predecessor`), `Git`, `Scope`, `FullSuite`, `ContentScan`, `Learning`, `Advisory`. New checks add `Digest::SHA256` (standard library) and `YAML.safe_load` with `permitted_classes: [Time, Date]` and `aliases: true`, the options `recorded_commit` already uses.
- The sealing command depends on `Gate#evaluate`, `ChangeRecord#update_metadata` and `update_handoff` (both take the record lock, `record_lock_test.rb`), `Git#run`, and the pre-commit hook, which runs `ci` on every commit it makes.
- `PhaseRunner` and the parallel path in `CLI` depend on the sealing command; `mark_blocked!` must run before it so a blocked handoff is never sealed as complete.
- `HarnessEval` lint depends on `Gate::CHECKS` naming every check a case may expect.
- `Scope#change_base` and `specification_lock_check` depend on `recorded_commit`, which depends on the handoff being committed: the dependency this change turns from a convention into a guarantee.
- `test/lifecycle_fixture.rb` and `test_helper.rb#complete_phase!` are shared by the phase-lifecycle, release, close and parallel tests; a change to what "complete" requires (a recorded predecessor) touches every test that completes phases without committing.

## External services and libraries
- Ruby (version per `.ruby-version`), `psych` (YAML), `digest`, `fileutils`, `json`, `securerandom`: standard library only. No new gem.
- `git` on PATH, as today. Sealing commits need `user.name` and `user.email` in the repository or global config; the fixture repositories set them (`test_helper.rb#configure_git`).
- Coding shells (`claude`, `codex`, `grok`) for `phase run`; the sealing step runs in the parent process after the shell exits, so it does not depend on which shell ran.
- No network. `learn promote` and `check` are local.

## Infrastructure dependencies
- The pre-commit hook (`soft-foundry hooks install`) `exec`s `soft-foundry ci`. Every sealing commit therefore runs `check`, the gate harness evals, and the gate over every open record; at `a0a8460` that took about two minutes. The sealing command must not bypass it (`--no-verify` would defeat the hook's purpose), so a phase's completion cost includes one `ci` run.
- GitHub Actions in this repository run the suite with no provider keys in the environment; the suite's `SOFT_FOUNDRY_PHASE` isolation matters for a contributor's machine, not CI.
- No deployment target; the gem is built and installed locally (never pushed to RubyGems).
