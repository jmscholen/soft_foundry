# Dependencies

## Internal dependencies
- `Gate#staleness_check` depends on `Git` (`changed_since`, `changed_between`, `branch_tip`, `ancestor?`, `commit?`), `ControlPlane#code_globs` and `match_any?`, and `ChangeRecord#metadata`. Scoping changes the inputs to the filter; the lock-commit specification check and the stacked-branch tip logic must keep working unchanged.
- Consumers of the stale result: `PhaseRunner#refusal`, `Snapshot` (status and UI), `Advisory`, and harness-eval gate cases. A change in what counts as stale propagates to all of them through `Gate::Result#stale?`.
- Path groups: `.ai/paths.yml` defaults overridden by `.ai/repository.yml` `paths:`; `check_path_groups` already refuses overrides that make staleness blind. New declarations (shared core, access-control paths, scope) need the same blind-spot protection.
- Skill contracts and templates: verification `tests.yml` and `evidence/manifest.yml`, evaluation and attack skills, and `skill.yml` `evidence: commit_bound`.
- Control-plane docs and `check` descriptions must change together (`.ai/README.md`, `.ai/schemas.md`, `CHECK_DESCRIPTIONS` in gate.rb).
- Stacked work: changes B (phase reopen, parallel runs, released state) and C (smaller fixes) build on this one; the record format chosen here is their input.

## External services and libraries
- `git` CLI (git 2.39 locally; `rev-parse <sha>^{tree}` is long-standing). Ruby standard library only (YAML, Open3, Minitest); no runtime gem dependency is added or needed.
- The governed application's test suite (for example a Rails app's 11.5-minute full run) is external; Soft Foundry never runs it, only records and checks what the verify session cites.

## Infrastructure dependencies
N/A. GitHub Actions CI (`bundle exec rake test`, `bundle exec rake ci`) runs the gem's own tests and gates every record; no deployed service.
