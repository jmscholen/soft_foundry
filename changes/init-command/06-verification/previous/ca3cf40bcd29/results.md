# Verification Results

Commit SHA: ca3cf40bcd299e98bfd821c3cc9c0d70e79e27ad (branch `change/init-command`)

Rerun after remediation. The previous verification run at 6df4d15e73d8d8bf53555e73addbf42ca7b3494f is archived, unmodified, under `previous/6df4d15e73d8/`; this document and the top-level `evidence/` describe the remediated code only. Between the two runs the implementation changed in `lib/soft_foundry/cli.rb`, `lib/soft_foundry/onboarding.rb`, `lib/soft_foundry/provider.rb`, `lib/soft_foundry/gate.rb`, `test/cli_init_test.rb`, and `test/gate_test.rb` (commit 420acdc, see `09-remediation/summary.md`).

Runtime: ruby 3.3.1 (2024-04-23 revision c56cd86388) [arm64-darwin23], the asdf shim resolving to `/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby`; every scratch-directory run used that absolute binary so asdf could not resolve a different Ruby there. `git status --porcelain` was empty before this phase started; at every capture point afterwards, `git status --porcelain -- . ':!changes/init-command/06-verification'` was empty, so nothing outside this phase directory was modified. No `.gem` file was left in the repository. All commands were run from the repository root unless stated otherwise. Full stdout and stderr of every check are in `evidence/`.

## Deterministic checks

| # | Check | Command | Result | Exit | Evidence |
| --- | --- | --- | --- | --- | --- |
| 1 | Git state | `git rev-parse HEAD; git status --porcelain` | pass (clean; HEAD ca3cf40) | 0 | `evidence/git-state.log` |
| 2 | Ruby version | `which ruby; ruby -v` | 3.3.1 | 0 | `evidence/ruby-version.log` |
| 3 | Unit and integration tests | `bundle exec rake test` (bundler available; fallback runner not needed) | pass: 71 runs, 755 assertions, 0 failures, 0 errors, 0 skips, zero warnings | 0 | `evidence/tests.log` |
| 4 | Syntax and warnings | `ruby -wc` on all 18 files under `lib/` | pass: 18 x `Syntax OK`, zero warnings | 0 | `evidence/ruby-wc.log` |
| 5 | Control-plane lint | `ruby -Ilib exe/soft-foundry check` | pass: 16 phases, 16 skills, no errors | 0 | `evidence/check.log` |
| 6 | CI | `ruby -Ilib exe/soft-foundry ci` | pass: control plane ok; `init-command` 00-05 PASS, 07-evaluation blocked (reported, not failing), 09-remediation PASS via `repairing blocked 07-evaluation`; `upstream-failure-reporting` 00-intake PASS | 0 | `evidence/ci.log` |
| 7 | Doctor on this repository | `ruby -Ilib exe/soft-foundry doctor` | as expected: `.ai/manifest.yml` and `local runtime` reported missing; pre-commit hook present | 2 | `evidence/doctor.log` |
| 8 | Dry-run on this repository | `ruby -Ilib exe/soft-foundry init --dry-run --no-onboard` | pass: `mode: dry run, nothing written`; 170 skipped, `created CLAUDE.md` only; worktree unchanged afterwards | 0 | `evidence/init-dry-run-self.log` |
| 9 | Gem packaging | `gem build soft_foundry.gemspec --output <scratch>` in an rsync copy; `tar -xOf <gem> data.tar.gz \| tar -tz`; `gem specification <gem> required_ruby_version` | pass: soft_foundry 0.2.0, 189 files; `changes/README.md`, `docs/user/README.md`, `.ai/templates/repository.yml`, `.ai/workflow.yml`, `exe/soft-foundry`, `AGENTS.md` present; `.ai/harness-evals/README.md` the only harness-evals entry; `.ai/manifest.yml` not packaged; `required_ruby_version >= 3.2`; no `.gem` in the repository | 0 | `evidence/gem-build.log` |
| 10 | End-to-end install | scratch git repository with `app.rb`; `init --no-onboard` twice; `check`; `doctor`; installed-state inspection; edit and commit `.ai/rules/general.md`; `init`; `init --force`; `init` | pass, see below | 0 / 0 / 0 / 2 / 3 / 0 / 0 | `evidence/e2e-install.log` |
| 11 | Manifest integrity in the e2e target | `ruby verify_manifest.rb <target>` (YAML `safe_load` without aliases, compare against every `.ai/` file, recompute SHA-256) | pass: 165 entries, 0 mismatches, 0 malformed, only `.ai/repository.yml` excluded (by rule) | 0 | `evidence/e2e-manifest-verify.log` |
| 12 | Remediation-specific checks | second scratch git repository: `init --root` with no value; two committed edits then `init` (conflict) and `init --force`; `init` with onboarding and `OPENAI_API_KEY ANTHROPIC_API_KEY XAI_API_KEY` unset | pass, see below | 1 / 3 / 0 / 0 | `evidence/remediation-checks.log` |
| 13 | `init --help` probe (EVAL-F-002 carry-forward, not a required gate) | `init --help`; `init -h`; `help` | fail: no per-command help; `unknown option(s): --help` | 1 / 1 / 1 | `evidence/init-help-probe.log` |
| 14 | Below-floor Ruby probe (VER-004 carry-forward, not a required gate) | `/Users/jscholen-iou/.asdf/installs/ruby/2.7.8/bin/ruby -Ilib exe/soft-foundry version` and `init --dry-run --no-onboard` | error: `SyntaxError` on endless method definitions, no version guidance | 1 / 1 | `evidence/e2e-install-ruby27-attempt.log` |

### End-to-end install detail (check 10)
- First `init --no-onboard`: exit 0; `root:` printed first; 171 files `created`; `check: ok`; `summary: created 171, updated 0, skipped 0, conflict 0, forced 0`. `app.rb` SHA-256 `8598a686...` identical before and after. `git status --porcelain` after committing the run: empty.
- Second `init --no-onboard`: exit 0; all 171 lines `skipped`; no `created`/`updated`/`conflict`/`forced` line; `summary: created 0, updated 0, skipped 171, conflict 0, forced 0`; `git status --porcelain` empty.
- `soft-foundry check` in the target: exit 0, 16 phases, 16 skills, no errors.
- `soft-foundry doctor` in the target: exit 2; `.ai/manifest.yml` present; `pre-commit hook` and `local runtime` absent, expected because `--no-onboard` was used and no hook was installed.
- Installed state: `.ai/manifest.yml` records `version: 1`, `soft_foundry_version: 0.2.0`; `.ai/repository.yml` has `assessed: false` and `capabilities: {}`; `.ai/harness-evals/` contains only `README.md`; `.gitignore` is `.soft-foundry/` and `git check-ignore -v` confirms it is effective; `AGENTS.md` and `CLAUDE.md` each carry one `<!-- soft-foundry:begin -->` block; `docs/user/README.md` and `changes/README.md` exist.
- After appending a maintainer note to `.ai/rules/general.md` and committing: `init --no-onboard` exit 3 with `conflict  .ai/rules/general.md  (differs from manifest hash)`, 170 skipped, then the two new report lines `conflicts: .ai/rules/general.md` and `next: compare with `git diff`, keep your version, or commit it and rerun with --force to take the canonical version (uncommitted edits are never overwritten)`; worktree untouched.
- `init --force --no-onboard`: exit 0 with `forced    .ai/rules/general.md  (differs from manifest hash)`; `git diff --stat` shows the 3 maintainer lines removed; on-disk SHA-256 `4ea1f1dd...` equals the manifest entry. No `conflicts:`/`next:` line is printed on a forced run.
- Final `init --no-onboard`: exit 0, 171 skipped.

### Remediation-specific detail (check 12)
Verbatim from `evidence/remediation-checks.log`:
- R1, EVAL-F-001: `soft-foundry init --root` exits 1. Combined stdout+stderr is exactly one line: `soft-foundry: --root requires a value`. Zero matches for `defect in Soft Foundry`, `internal failure`, or pull-request guidance. Nothing was written to the target.
- R2, EVAL-F-003 and EVAL-F-004: after committed edits to `.ai/rules/general.md` and `.ai/rules/ruby.md`, `init --no-onboard` exits 3 and prints, after the summary, `conflicts: .ai/rules/general.md, .ai/rules/ruby.md` and `next: compare with `git diff`, keep your version, or commit it and rerun with --force to take the canonical version (uncommitted edits are never overwritten)`. Both paths are named; the `next:` line mentions `--force`. After stripping the output to printable ASCII the status words remain identifiable (2 `conflict`, 169 `skipped`). `init --force --no-onboard` then exits 0 with two `forced` lines.
- R3, EVAL-F-005 and AC-015: `env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY -u XAI_API_KEY soft-foundry init` exits 0 and prints `openai     not configured (set OPENAI_API_KEY)`, `anthropic  not configured (set ANTHROPIC_API_KEY)`, `xai        not configured (set XAI_API_KEY)`; `.soft-foundry/runtime.yml` exists with `configured: false` for all three providers and is ignored via `.gitignore:1:.soft-foundry/`.

## Acceptance criteria to automated tests

Mapping taken from the `# AC-nnn` comments on test methods (`grep -n "AC-0" test/*.rb`). All tests are in `test/cli_init_test.rb` unless another file is named.

| Criterion | Automated test | End-to-end evidence |
| --- | --- | --- |
| AC-001 | `test_clean_install_installs_canonical_set_and_manifest` | check 10 first run, check 11 |
| AC-002 | `test_refuses_non_git_target_without_flag` | none |
| AC-003 | `test_second_run_skips_everything_and_leaves_tree_clean` | check 10 second run |
| AC-004 | `test_agents_and_claude_preserved_and_block_appended_once`; unit `agent_files_test.rb#test_existing_text_preserved_and_block_appended_once` | none (pointer files absent in the e2e target) |
| AC-005 | same test as AC-004; unit `agent_files_test.rb#test_legacy_claude_block_is_recognized` | none |
| AC-006 | `test_user_edited_rule_is_conflict_then_force_overwrites` | check 10 conflict run, check 12 R2 |
| AC-007 | same test as AC-006 | check 10 `--force` run, check 11, check 12 R2 |
| AC-008 | `test_preexisting_ai_without_manifest` | none |
| AC-009 | `test_gitignore_already_effective_is_skipped` | none |
| AC-010 | folded into `test_clean_install_installs_canonical_set_and_manifest`; unit `installer_source_test.rb` | check 10 installed state |
| AC-011 | `test_docs_user_not_created_when_docs_exists_without_user` | none |
| AC-012 | `test_dry_run_matches_real_report_and_writes_nothing` | check 8 |
| AC-013 | `test_missing_packaged_workflow_is_internal_error_exit_4_with_upstream_guidance` (also tagged MIT-012) | none |
| AC-014 | `test_symlinked_ai_outside_root_is_refused` | none |
| AC-015 | `test_init_runs_onboarding_and_provider_errors_do_not_fail` | check 12 R3 |
| AC-016 | folded into `test_clean_install_installs_canonical_set_and_manifest` | check 10 and check 12 R2 (ASCII-stripped status words) |
| AC-017 | `test_gemspec_declares_ruby_32_and_packages_scaffolding` | check 9 |

Remediation tests, not bound to an acceptance criterion: `test_root_without_value_is_a_usage_error_not_an_internal_failure` (EVAL-F-001) and `test_conflict_report_names_paths_and_next_step` (EVAL-F-003, EVAL-F-004) in `cli_init_test.rb`; `test_remediation_may_complete_while_an_earlier_phase_is_blocked` and `test_remediation_still_needs_a_complete_predecessor_when_nothing_is_blocked` in `gate_test.rb`. EVAL-F-005 (the env var name in "not configured") has no dedicated automated test; it is covered only by check 12 R3 here.

Every criterion has at least one automated test. Gaps in depth, unchanged from the previous run:
- AC-010 and AC-016 have no dedicated test; they live inside the AC-001 test, and AC-016 is asserted there for the `created` word only.
- The `updated` status for a managed `.ai/` file (manifest hash matches, canonical content differs; the upgrade path) still has no automated test and no end-to-end evidence; `updated` is only exercised for `AGENTS.md`/`CLAUDE.md`. The planned MIT-003 test was not written.
- From the threat-driven list in `04-plan/testing.md`, `..` traversal in packaged names (MIT-002) and hashing a large managed file without reading it into memory (MIT-014) have no test.

## Failures
No required check failed. Observations that are not failures of the change:
- `doctor` on this repository exits 2 because `.ai/manifest.yml` is absent (self-install deliberately not performed by implementation) and no local runtime exists.
- `init --help` and `init -h` exit 1 with `unknown option(s)`; there is no per-command help (EVAL-F-002, deliberately deferred by remediation as REM-002). `soft-foundry help` prints the usage and then exits 1, because `help` is not a recognised command.
- Running from source under Ruby 2.7.8 (below the declared `>= 3.2` floor) fails at load with `SyntaxError` on the endless method definitions in `lib/soft_foundry/cli.rb` (lines 63, 140, 141) instead of a version message; `gem install` would refuse via `required_ruby_version`. Reproduced deliberately this time (check 14).
- `gem build` warns that the gemspec has no license and no homepage.
- The MIT-004(b) `git diff` hint for `updated`/`forced` files is still not printed after a forced run (check 10, `--force` step). The new `next:` line does mention `git diff`, but only on conflict runs.
- `.soft-foundry/init.lock` (0 bytes) remains in the target after every run. It is the flock file, lives under the gitignored directory, and does not affect idempotence; noted for documentation.
- Implementation deviations in `05-implementation/deviations.md` remain as recorded: `.ai/templates/repository.yml` is packaged and installs as an unassessed `.ai/repository.yml`; `AGENTS.md` in this repository carries the begin/end markers; `README.md` and `docs/user/README.md` still contain no user documentation for `init` (the only `init` mentions in `README.md` are the change-record pointer).

## Evidence
All under `changes/init-command/06-verification/evidence/`, hashed in `evidence/manifest.yml` (the archived run's evidence is under `previous/6df4d15e73d8/` and is not listed there):
- `git-state.log`, `ruby-version.log`
- `tests.log`, `ruby-wc.log`
- `check.log`, `ci.log`, `doctor.log`
- `init-dry-run-self.log`
- `gem-build.log`
- `e2e-install.log`, `e2e-manifest-verify.log`
- `remediation-checks.log`
- `init-help-probe.log`, `e2e-install-ruby27-attempt.log`

Evidence generated for a different implementation commit is stale.
