# Verification Results

Commit SHA: 147fca6362dd7da21b41fcd280ad3f3d247686da (branch `change/init-command`)

Fourth run, by a fresh-context agent under verification permissions, after the second remediation (attack findings V1..V7). The three earlier runs are archived, unmodified, under `previous/6df4d15e73d8/` (first verification), `previous/ca3cf40bcd29/` (rerun after the first remediation, evaluation findings), and `previous/52971d8f2fbc/` (third rerun, harness-loop-semantics change only). This document and the top-level `evidence/` describe HEAD only.

Between the remediation commit `1fb8aa73a4ddae7cfb1a02f313b687286ee83581` and HEAD `147fca6`, `git diff --stat 1fb8aa7..147fca6` touches only `changes/init-command/09-remediation/handoff.yml` and `changes/init-command/metadata.yml`; nothing under `lib/`, `test/`, `exe/`, or `soft_foundry.gemspec` changed, so the code exercised here is exactly the code `09-remediation/summary.md` describes as fixing V1..V7.

## Pre-existing partial evidence (reported per instructions, then overwritten)

At the start of this run, `git status --porcelain` showed seven modified-but-uncommitted files under `changes/init-command/06-verification/evidence/` (`ci.log`, `gem-build.log`, `git-state.log`, `init-dry-run-self.log`, `ruby-version.log`, `ruby-wc.log`, `tests.log`), left by a previous attempt at this same run that was stopped early. The top-level `results.md`, `tests.yml`, and the other evidence files still held the stale content of the archived third run (`52971d8f2fbc`, byte-identical to `previous/52971d8f2fbc/results.md`), while `handoff.yml` had already been correctly reset to `status: pending`. All of `results.md`, `tests.yml`, `evidence/manifest.yml`, every evidence log, and `handoff.yml` were regenerated from scratch for HEAD `147fca6` in this run, overwriting that partial and stale state. `previous/` (three directories) was not read for command output, only for the carried-forward finding list, and was not modified.

Runtime: `ruby 3.3.1 (2024-04-23 revision c56cd86388) [arm64-darwin23]`, resolved via `which ruby` from the repository root to the asdf shim, and confirmed with `RbConfig.ruby` to `/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby`; every scratch-directory invocation used that absolute binary path so that asdf could not resolve a different Ruby when the working directory changed. `git status --porcelain -- . ':!changes/init-command/06-verification'` was empty after every check that touched this repository (only this phase's own directory changed). No `.gem` file was left in the repository. All repository-root commands were run from the repository root; each scratch/e2e command's working directory is stated with it. Full stdout and stderr of every check are in `evidence/`.

## Deterministic checks

| # | Check | Command | Result | Exit | Evidence |
| --- | --- | --- | --- | --- | --- |
| 1 | Git state | `git rev-parse HEAD; git status --porcelain` | pass (HEAD 147fca6; 7 pre-existing partial evidence edits reported above, otherwise clean) | 0 | `evidence/git-state.log` |
| 2 | Unit and integration tests | `bundle exec rake test` | pass: 90 runs, 805 assertions, 0 failures, 0 errors, 0 skips | 0 | `evidence/tests.log` |
| 3 | Syntax and warnings | `ruby -wc` on all 19 files under `lib/`, including `lib/soft_foundry/safe_write.rb` | pass: 19 x `Syntax OK`, zero warnings | 0 | `evidence/ruby-wc.log` |
| 4 | Control-plane lint | `ruby -Ilib exe/soft-foundry check` | pass: 16 phases, 16 skills, no errors | 0 | `evidence/check.log` |
| 5 | CI | `ruby -Ilib exe/soft-foundry ci` | pass: control plane ok; `init-command` 00-05 PASS, `08-attack` reported `blocked PASS` (blocking findings recorded, gate itself valid), `09-remediation` PASS with `predecessor complete: 05-implementation`; 06/07 pending (skipped); `upstream-failure-reporting` 00-intake PASS | 0 | `evidence/ci.log` |
| 6 | Doctor on this repository | `ruby -Ilib exe/soft-foundry doctor` | as expected: `.ai/manifest.yml` and `local runtime` reported missing (self-install deliberately not performed); pre-commit hook present | 2 | `evidence/doctor.log` |
| 7 | Dry-run on this repository | `ruby -Ilib exe/soft-foundry init --dry-run --no-onboard` | pass: `mode: dry run, nothing written`; 170 skipped, `created CLAUDE.md` only; `summary: created 1, updated 0, skipped 170, conflict 0, forced 0`; neither `.ai/manifest.yml` nor `CLAUDE.md` exists afterwards; worktree outside this phase unchanged | 0 | `evidence/init-dry-run-self.log` |
| 8 | Gem packaging | `gem build soft_foundry.gemspec --output <scratch>` in an rsync copy (no `.git`); `tar -xOf <gem> data.tar.gz \| tar -tz`; `gem specification <gem> required_ruby_version` | pass: soft_foundry 0.2.0, 190 files; `lib/soft_foundry/safe_write.rb`, `changes/README.md`, `docs/user/README.md`, `.ai/templates/repository.yml` present; `.ai/harness-evals/README.md` the only harness-evals entry; `test/` and `changes/init-command` not packaged (0 matches each); `required_ruby_version >= 3.2`; no `.gem` left in the repository | 0 | `evidence/gem-build.log` |
| 9 | End-to-end install | scratch git repository, repo-root absolute ruby: `app.rb`, `init --no-onboard` twice, `check` in target, committed edit to `.ai/rules/general.md` then `init` (conflict) then `init --force`, `init --root` with no value, `onboard` with the three provider keys unset | pass, see detail below | 0/0/0/3/0/1/0 | `evidence/e2e-install.log` |
| 10 | Below-floor Ruby probe (VER-004 carry-forward, not a required gate) | `/Users/jscholen-iou/.asdf/installs/ruby/2.7.8/bin/ruby -Ilib exe/soft-foundry version` and `init --dry-run --no-onboard` | error: `SyntaxError` on endless method definitions (`cli.rb` lines 64, 157, 158), no version guidance | 1/1 | `evidence/e2e-install-ruby27-attempt.log` |
| 11 | `init --help` probe (VER-009 carry-forward, not a required gate) | `init --help`; `init -h`; `help` | fail: no per-command help; `unknown option(s): --help` / `-h`; `help` itself exits 1 after printing global usage | 1/1/1 | `evidence/init-help-probe.log` |

### End-to-end install detail (check 9)
- First `init --no-onboard`: exit 0; `root:` printed first; 171 files `created`; `summary: created 171, updated 0, skipped 0, conflict 0, forced 0`. `app.rb` SHA-256 `8598a686...` identical before and after.
- `git add -A && git commit`: clean commit of the installed tree.
- Second `init --no-onboard`: exit 0; all 171 lines `skipped`; `summary: created 0, updated 0, skipped 171, conflict 0, forced 0`.
- `soft-foundry check` in the target: `✓ control plane: 16 phases, 16 skills, no errors`, exit 0.
- After appending a maintainer note to `.ai/rules/general.md` and committing it: `init --no-onboard` exits 3 with `conflict  .ai/rules/general.md  (differs from manifest hash)`, `summary: created 0, updated 0, skipped 170, conflict 1, forced 0`, `conflicts: .ai/rules/general.md`, and `next: compare with \`git diff\`, keep your version, or commit it and rerun with --force to take the canonical version (uncommitted edits are never overwritten)`.
- `init --force --no-onboard`: exit 0 with `forced    .ai/rules/general.md  (differs from manifest hash)`; `summary: created 0, updated 0, skipped 170, conflict 0, forced 1`; no `conflicts:`/`next:` line.
- `init --root` (no value): exit 1, entire output is the single line `soft-foundry: --root requires a value`.
- `onboard` with `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `XAI_API_KEY` unset: exit 0; `openai     not configured (set OPENAI_API_KEY)`, `anthropic  not configured (set ANTHROPIC_API_KEY)`, `xai        not configured (set XAI_API_KEY)`; `.soft-foundry/runtime.yml` written with `configured: false` for all three providers.

## Remediation-specific checks (V1..V7 regression, each in its own scratch target)

| # | Case | Setup | Expected | Observed | Result |
| --- | --- | --- | --- | --- | --- |
| (a) | V1 temp-sibling symlink | committed symlink at `.ai/workflow.yml.soft-foundry-tmp` -> an outside victim file | exit 1 naming the temp sibling; victim unchanged; nothing written | `soft-foundry: .ai/workflow.yml.soft-foundry-tmp exists (planted or leftover temporary file); remove it and rerun`; exit 1; victim byte-identical before/after; `git status --porcelain` empty; `.ai/` holds only the symlink | pass |
| (b) | V2 `.soft-foundry` directory symlink | `.soft-foundry -> <outside empty dir>` | exit 1; outside directory still empty | `soft-foundry: <path>/.soft-foundry is a symlink; refusing to write through it`; exit 1; outside directory still 0 entries | pass |
| (c) | V2 `runtime.yml` symlink | clean install, then `.soft-foundry/runtime.yml -> <outside victim>`, `onboard` with keys unset | exit 1; victim unchanged | `soft-foundry: <path>/.soft-foundry/runtime.yml is a symlink; refusing to write through it`; exit 1; victim byte-identical before/after | pass |
| (d) | V3 git-ignored uncommitted edit | clean install and commit, `.ai/rules/` added to `.gitignore`, `git rm -r --cached .ai/rules`, commit, then an **uncommitted** hand edit to `.ai/rules/general.md`, `init --force` | `conflict ... (uncommitted modifications)`; file unchanged; exit 3 | `conflict  .ai/rules/general.md  (uncommitted modifications)`; file still ends with the uncommitted hand-edit line after the run (untouched even under `--force`); exit 3 | pass |
| (e) | V4 protected path-group override | `.ai/repository.yml` overridden with `paths: {HARNESS_EVALS: [nothing/**]}`, then `check` | error naming the protected group | `✗ repository.yml overrides protected path group HARNESS_EVALS; the default is kept and the override must be removed`; exit 2 | pass |
| (f) | V5 misclassification | regular file at `.soft-foundry`, then `init` | exit 1 (not 4), no "defect in Soft Foundry" text | `soft-foundry: <path>/.soft-foundry is not a directory`; exit 1; no defect/upstream text | pass |
| (g) | V6 FIFO hang | FIFO at `.ai/manifest.yml`, `init` under `timeout 10` | prompt exit 1, no hang | `soft-foundry: .ai/manifest.yml is not a regular file`; exit 1; elapsed 1s | pass |
| (h) | V1/V5 cross-directory + tampered package | `init --root <scratch-target> --allow-non-git` invoked from `/private/tmp` against a copy of the repo with `.ai/workflow.yml` deleted | exit 4; indented diagnostic lines free of the target's absolute path | exit 4; body is `This is a defect in Soft Foundry 0.2.0, not in your repository. Nothing was changed.` / `diagnostic:` / `  source: <soft-foundry>` / upstream fork guidance / `  gh repo fork jmscholen/soft_foundry --clone`; the target's absolute path (`.../scratchpad/rem-h`) appears nowhere in the program's output, only in this report's own setup commentary | pass |

All eight remediation-specific checks behave as required by `09-remediation/summary.md`; V1..V7 are not reproducible at HEAD in these scenarios. Evidence: `evidence/remediation-checks.log` (sections in order (a)-(h)).

## Acceptance criteria to automated tests

Mapping from `# AC-nnn` comments in `test/cli_init_test.rb` (`grep -n '# AC-0' test/*.rb`). Unchanged from the archived third run because `test/cli_init_test.rb`'s AC-tagged tests did not change in the remediation.

| Criterion | Automated test | End-to-end evidence |
| --- | --- | --- |
| AC-001 | `test_clean_install_installs_canonical_set_and_manifest` | check 9 first run |
| AC-002 | `test_refuses_non_git_target_without_flag` | none |
| AC-003 | `test_second_run_skips_everything_and_leaves_tree_clean` | check 9 second run |
| AC-004 | `test_agents_and_claude_preserved_and_block_appended_once` | none (pointer files absent in the e2e target's `app.rb`-only seed) |
| AC-005 | same test as AC-004 | none |
| AC-006 | `test_user_edited_rule_is_conflict_then_force_overwrites` | check 9 conflict run |
| AC-007 | same test as AC-006 | check 9 `--force` run |
| AC-008 | `test_preexisting_ai_without_manifest` | none |
| AC-009 | `test_gitignore_already_effective_is_skipped` | none |
| AC-010 | folded into `test_clean_install_installs_canonical_set_and_manifest` (tagged) | check 9 |
| AC-011 | `test_docs_user_not_created_when_docs_exists_without_user` | none |
| AC-012 | `test_dry_run_matches_real_report_and_writes_nothing` | check 7 |
| AC-013 | `test_missing_packaged_workflow_is_internal_error_exit_4_with_upstream_guidance` | check (h) (same failure mode reproduced end-to-end) |
| AC-014 | `test_symlinked_ai_outside_root_is_refused` | checks (a)-(c) exercise the same symlink-refusal family at other paths |
| AC-015 | `test_init_runs_onboarding_and_provider_errors_do_not_fail` | check 9 onboarding run |
| AC-016 | folded into `test_clean_install_installs_canonical_set_and_manifest` (tagged) | check 9 (status words legible) |
| AC-017 | `test_gemspec_declares_ruby_32_and_packages_scaffolding` | check 8 |

Every criterion has at least one automated test; no mapping gap.

## Violations V1..V7 to regression tests

Mapping from `# ATTACK-nnn` comments (`grep -n '# ATTACK-' test/*.rb`).

| Violation | Attack case | Test(s) | Fix location (per `09-remediation/summary.md`) |
| --- | --- | --- | --- |
| V1 (critical): temp-sibling symlink | ATTACK-004 | `installer_test.rb#test_planted_temp_sibling_symlink_is_refused_and_victim_untouched` | `lib/soft_foundry/safe_write.rb` (new): `O_EXCL\|O_NOFOLLOW` on the temp sibling |
| V2 (major): `.soft-foundry/` unguarded | ATTACK-005 | `installer_test.rb#test_soft_foundry_dir_symlink_is_refused`, `installer_test.rb#test_runtime_yml_symlink_is_refused_by_onboarding` | `installer.rb`, `onboarding.rb` guard the directory and `runtime.yml` before any write |
| V3 (major): uncommitted-edit bypasses | ATTACK-021 | `installer_test.rb#test_git_ignored_uncommitted_edit_is_still_a_conflict_even_under_force`, `installer_test.rb#test_allow_non_git_inside_a_repository_still_protects_uncommitted_edits` | `git.rb#dirty_paths` includes ignored paths; dirty detection applies whenever a repository exists |
| V4 (major): redirected path-group overrides | ATTACK-013 | `check_test.rb#test_protected_group_override_is_an_error_and_ignored`, `check_test.rb#test_redirected_app_override_matching_nothing_is_an_error` | `control_plane.rb`, `check.rb`: `CONTROL_PLANE`/`HARNESS_EVALS` cannot be overridden; emptied-vs-defaults override is an error |
| V5 (major): misclassification as internal defect, path leakage | ATTACK-015 | `cli_init_test.rb#test_regular_file_at_soft_foundry_is_target_side`, `cli_init_test.rb#test_invalid_user_yaml_under_ai_is_target_side`, `cli_init_test.rb#test_diagnostic_hides_resolved_root_when_cwd_is_elsewhere`, `installer_test.rb#test_plan_is_not_clean_when_ai_has_extra_or_preexisting_files` | `cli.rb`: sanitizer uses the resolved root, catches post-install check failures, refuses `/` |
| V6 (minor): FIFO hangs | ATTACK-006 | `installer_test.rb#test_fifo_at_manifest_or_gitignore_is_refused_without_hanging` | `manifest.rb` refuses non-regular files before reading |
| V7 (minor): raw provider strings | ATTACK-019 | `provider_test.rb#test_sanitize_truncates_long_values` | `provider.rb`: sanitizes and truncates ids/errors to 200 characters |

All seven violations have at least one dedicated regression test, and all seven were independently reproduced-and-found-fixed live in this run's remediation-specific checks (a)-(h) above. No mapping gap.

## Failures
No required check failed. Observations that are not failures of this change, carried from earlier runs and reconfirmed at HEAD:
- `doctor` on this repository exits 2 because `.ai/manifest.yml` is absent (self-install deliberately not performed by implementation) and no local runtime exists.
- `init --help` and `init -h` exit 1 with `unknown option(s)`; there is no per-command help; `soft-foundry help` itself exits 1 after printing the global usage (VER-009, carried from EVAL-F-002 / REM-002, deliberately not remediated).
- Running from source under Ruby 2.7.8 (below the declared `>= 3.2` floor) fails at load with `SyntaxError` on endless method definitions in `lib/soft_foundry/cli.rb` (lines 64, 157, 158) instead of a version message; `gem install` would refuse via `required_ruby_version` (VER-004).
- `gem build` warns that the gemspec has no license and no homepage (VER-005).
- `09-remediation/summary.md` records residual items not addressed by this remediation: the home-directory `--root` warning (MIT-008), a memory bound for very large files (MIT-014), local git excludes (`.git/info/exclude`, repo-local `core.excludesFile`) still leaving `.gitignore`'s `.soft-foundry/` line unadded on that machine, and `docs` symlink refusal aborting the whole run instead of only skipping `docs/user/README.md`. None of these are V1..V7 and none regressed in this run's checks.
- Implementation deviations in `05-implementation/deviations.md` remain as recorded: `.ai/templates/repository.yml` is packaged and installs as an unassessed `.ai/repository.yml`; `AGENTS.md` in this repository carries the begin/end markers; `README.md` and `docs/user/README.md` still contain no user documentation for `init`.
- The `updated` status for a managed `.ai/` file (manifest hash matches, canonical content differs; the upgrade path) still has no automated test and no end-to-end evidence in this run; `updated` is only exercised for `AGENTS.md`/`CLAUDE.md`. `..` traversal in packaged names (MIT-002) and hashing a large managed file without reading it fully into memory (MIT-014) still have no test.

## Evidence
All under `changes/init-command/06-verification/evidence/`, hashed in `evidence/manifest.yml` (the three archived runs' evidence lives under `previous/6df4d15e73d8/`, `previous/ca3cf40bcd29/`, and `previous/52971d8f2fbc/` and is not listed there):
- `git-state.log`, `ruby-version.log`
- `tests.log`, `ruby-wc.log`
- `check.log`, `ci.log`, `doctor.log`
- `init-dry-run-self.log`
- `gem-build.log`
- `e2e-install.log`
- `remediation-checks.log` (new structure in this run: sections (a)-(h) covering V1..V7)
- `init-help-probe.log`, `e2e-install-ruby27-attempt.log`

Evidence generated for a different implementation commit is stale.
