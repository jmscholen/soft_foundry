# Verification Results

Commit SHA: 6df4d15e73d8d8bf53555e73addbf42ca7b3494f (branch `change/init-command`)

Runtime: ruby 3.3.1 (2024-04-23 revision c56cd86388) [arm64-darwin23], resolved by asdf from the repository. `git status --porcelain` was empty before this phase started; the only untracked paths during the run were this phase's own evidence files (`evidence/git-state.log`). No file outside `changes/init-command/06-verification/` was modified by this phase, and no `.gem` file was left in the repository.

All commands were run from the repository root unless stated otherwise. Full stdout and stderr of every check are in `evidence/`.

## Deterministic checks

| # | Check | Command | Result | Exit | Evidence |
| --- | --- | --- | --- | --- | --- |
| 1 | Git state | `git rev-parse HEAD; git status --porcelain` | pass (clean) | 0 | `evidence/git-state.log` |
| 2 | Ruby version | `ruby -v` | 3.3.1 | 0 | `evidence/ruby-version.log` |
| 3 | Unit and integration tests | `bundle exec rake test` (bundler available; fallback runner not needed) | pass: 67 runs, 740 assertions, 0 failures, 0 errors, 0 skips | 0 | `evidence/tests.log` |
| 4 | Syntax and warnings | `ruby -wc` on all 18 files under `lib/` | pass: 18 x `Syntax OK`, zero warnings | 0 | `evidence/ruby-wc.log` |
| 5 | Control-plane lint | `ruby -Ilib exe/soft-foundry check` | pass: 16 phases, 16 skills, no errors | 0 | `evidence/check.log` |
| 6 | CI | `ruby -Ilib exe/soft-foundry ci` | pass: control plane ok; phases 00-05 of `init-command` PASS; `upstream-failure-reporting` 00-intake PASS | 0 | `evidence/ci.log` |
| 7 | Doctor on this repository | `ruby -Ilib exe/soft-foundry doctor` | as expected: `.ai/manifest.yml` and `local runtime` reported missing; the new manifest line is present | 2 | `evidence/doctor.log` |
| 8 | Dry-run on this repository | `ruby -Ilib exe/soft-foundry init --dry-run --no-onboard` | pass: `mode: dry run, nothing written`; 170 skipped, `created CLAUDE.md` only; worktree unchanged afterwards | 0 | `evidence/init-dry-run-self.log` |
| 9 | Gem packaging | `gem build soft_foundry.gemspec --output <scratch>` in an rsync copy; `tar -xOf <gem> data.tar.gz \| tar -tz` | pass: soft_foundry 0.2.0, 189 files; `changes/README.md`, `docs/user/README.md`, `.ai/templates/repository.yml` present; `.ai/harness-evals/README.md` is the only harness-evals entry; `.ai/manifest.yml` not packaged; `required_ruby_version >= 3.2` | 0 | `evidence/gem-build.log` |
| 10 | End-to-end install | scratch git repository with `app.rb`; `init --no-onboard` twice; `check`; `doctor`; edit and commit `.ai/rules/general.md`; `init`; `init --force`; `init` | pass, see below | 0 / 0 / 0 / 2 / 3 / 0 / 0 | `evidence/e2e-install.log` |
| 11 | Manifest integrity in the e2e target | `ruby verify_manifest.rb <target>` (YAML load, compare against every `.ai/` file, recompute SHA-256) | pass: 165 entries, 0 mismatches, only `.ai/repository.yml` excluded (by rule) | 0 | `evidence/e2e-manifest-verify.log` |
| 12 | End-to-end first attempt (environment error) | same script, scratch directory resolved `ruby` to 2.7.8 | error in setup, not in the change; retained as evidence | 1 | `evidence/e2e-install-ruby27-attempt.log` |

### End-to-end install detail (check 10)
- First `init --no-onboard`: exit 0; `root:` printed first; 171 files `created` (166 under `.ai/`, `.gitignore`, `AGENTS.md`, `CLAUDE.md`, `changes/README.md`, `docs/user/README.md`); `check: ok`; `summary: created 171, updated 0, skipped 0, conflict 0, forced 0`. `app.rb` SHA-256 identical before and after. `git status --porcelain` after committing the run: empty.
- Second `init --no-onboard`: exit 0; every one of the 171 lines is `skipped`; no `created`/`updated`/`conflict`/`forced` line; `git status --porcelain` empty.
- `soft-foundry check` in the target: exit 0, 16 phases, 16 skills, no errors.
- `soft-foundry doctor` in the target: exit 2; `.ai/manifest.yml` present; `pre-commit hook` and `local runtime` absent, which is expected because `--no-onboard` was used and no hook was installed.
- Installed state: `.ai/manifest.yml` records `version: 1`, `soft_foundry_version: 0.2.0`; `.ai/repository.yml` has `assessed: false` and `capabilities: {}`; `.ai/harness-evals/` contains only `README.md`; `.gitignore` is `.soft-foundry/` and `git check-ignore` confirms it is effective; `AGENTS.md` and `CLAUDE.md` carry the `<!-- soft-foundry:begin -->` block; `docs/user/README.md` and `changes/README.md` exist.
- After appending a maintainer note to `.ai/rules/general.md` and committing: `init --no-onboard` exit 3 with `conflict  .ai/rules/general.md  (differs from manifest hash)`, 170 skipped, worktree untouched.
- `init --force --no-onboard`: exit 0 with `forced    .ai/rules/general.md  (differs from manifest hash)`; `git diff --stat` shows the two maintainer lines removed; on-disk SHA-256 of the file equals its manifest entry.
- Final `init --no-onboard`: exit 0, 171 skipped.

## Acceptance criteria to automated tests

All tests are in `test/cli_init_test.rb` unless another file is named. Names differ from the ones planned in `04-plan/testing.md` where the implementation merged criteria into one test.

| Criterion | Automated test | End-to-end evidence |
| --- | --- | --- |
| AC-001 | `test_clean_install_installs_canonical_set_and_manifest` | check 10 first run, check 11 |
| AC-002 | `test_refuses_non_git_target_without_flag` | none |
| AC-003 | `test_second_run_skips_everything_and_leaves_tree_clean` (asserts lstat mtimes and clean `git status`) | check 10 second run |
| AC-004 | `test_agents_and_claude_preserved_and_block_appended_once`; unit: `agent_files_test.rb#test_existing_text_preserved_and_block_appended_once` | none (pointer files were absent in the e2e target) |
| AC-005 | same test as AC-004; unit: `agent_files_test.rb#test_legacy_claude_block_is_recognized` | none |
| AC-006 | `test_user_edited_rule_is_conflict_then_force_overwrites` | check 10 conflict run |
| AC-007 | same test as AC-006 | check 10 `--force` run, check 11 |
| AC-008 | `test_preexisting_ai_without_manifest` | none |
| AC-009 | `test_gitignore_already_effective_is_skipped`; unit: `installer_test.rb#test_gitignore_negation_is_conflict_and_effective_entry_is_skipped` | none |
| AC-010 | folded into `test_clean_install_installs_canonical_set_and_manifest`; unit: `installer_source_test.rb#test_packaged_set_has_the_two_exceptions_and_scaffolding` | check 10 step 5 |
| AC-011 | `test_docs_user_not_created_when_docs_exists_without_user` | none |
| AC-012 | `test_dry_run_matches_real_report_and_writes_nothing` | check 8 (dry-run on this repository) |
| AC-013 | `test_missing_packaged_workflow_is_internal_error_exit_4_with_upstream_guidance`; unit: `installer_source_test.rb#test_missing_required_file_is_internal_error` | none |
| AC-014 | `test_symlinked_ai_outside_root_is_refused` | none |
| AC-015 | `test_init_runs_onboarding_and_provider_errors_do_not_fail` | none (`--no-onboard` used in e2e) |
| AC-016 | folded into `test_clean_install_installs_canonical_set_and_manifest` (one regex on ASCII-stripped output for the `created` word only) | check 10: `created`, `skipped`, `conflict`, `forced` all appear as words |
| AC-017 | `test_gemspec_declares_ruby_32_and_packages_scaffolding` | check 9 (built gem inspected) |

Every criterion has at least one automated test. Gaps in depth rather than presence:
- AC-016 is asserted for a single status word; `updated`, `skipped`, `conflict`, `forced` are matched in other tests without ASCII stripping. The report emits only ASCII in practice, so this is a weak assertion rather than a defect.
- AC-010 and AC-016 have no dedicated test; they live inside the AC-001 test.
- The `updated` status for a managed `.ai/` file (manifest hash matches, canonical content differs, the upgrade path) has no automated test and no end-to-end evidence: `updated` is only exercised for `AGENTS.md`/`CLAUDE.md`. The proposed `test_altered_canonical_file_is_reported_updated_not_skipped` (MIT-003) was not written.
- From the threat-driven list in `04-plan/testing.md`: `..` traversal in packaged names (MIT-002) and hashing of a large managed file without reading it into memory (MIT-014) have no test. Symlinked packaged entry, FIFO, internal symlink, alias-bomb manifest, lock, forced-scope, uncommitted-conflict, write-failure, `--root` non-toplevel, and model-id sanitization are covered (`installer_test.rb`, `installer_source_test.rb`, `manifest_test.rb`, `provider_test.rb`, `cli_init_test.rb#test_root_must_be_toplevel`, `cli_init_test.rb#test_corrupt_manifest_is_target_error`).

## Failures
No required check failed. Observations that are not failures of the change:
- `doctor` on this repository exits 2 because `.ai/manifest.yml` is absent (self-install deliberately not performed by implementation) and no local runtime exists.
- The first end-to-end attempt (check 12) ran under Ruby 2.7.8 because the scratch directory had no asdf `.tool-versions`; it failed at load time with `SyntaxError` on the endless method definitions in `lib/soft_foundry/cli.rb` line 63. Below the declared floor, running from source gives no version guidance; `gem install` would refuse via `required_ruby_version`. The scenario was rerun with Ruby 3.3.1 pinned (check 10).
- `gem build` warns that the gemspec has no license and no homepage.
- The `git diff` hint line for `updated`/`forced` files described in MIT-004(b) is not printed by the implementation (check 10, `--force` run); the plan's design constraints DC-1 to DC-10 did not carry that sub-item, so this is recorded for review rather than as a failure.
- Implementation deviations in `05-implementation/deviations.md` were confirmed from the outside: `.ai/templates/repository.yml` is packaged and installs as an unassessed `.ai/repository.yml`; `AGENTS.md` in this repository carries the begin/end markers; no user documentation for `init` exists yet (`README.md`, `docs/user/README.md` unchanged).

## Evidence
All under `changes/init-command/06-verification/evidence/`, hashed in `evidence/manifest.yml`:
- `git-state.log`, `ruby-version.log`
- `tests.log`, `ruby-wc.log`
- `check.log`, `ci.log`, `doctor.log`
- `init-dry-run-self.log`
- `gem-build.log`
- `e2e-install.log`, `e2e-manifest-verify.log`, `e2e-install-ruby27-attempt.log`

Evidence generated for a different implementation commit is stale.
