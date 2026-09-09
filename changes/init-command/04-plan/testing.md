# Test Plan

## Unit
- `test/manifest_test.rb`: round-trip, schema rejection (missing version, non-hex hash, absolute or `..` path), unknown-entry warnings, aliases disabled.
- `test/installer_source_test.rb`: packaged set excludes `harness-evals/*` except README, `repository.yml`, `manifest.yml`; includes `changes/README.md` and `docs/user/README.md`; rejects a symlinked or traversing packaged entry (fixture source directory).
- `test/installer_plan_test.rb`: one test per status rule and per design constraint, on fixture trees, no CLI.
- `test/agent_files_test.rb`: create, append, skip on full block, conflict on bare marker, legacy single-marker `CLAUDE.md` recognized, symlinked pointer refused.
- `test/check_test.rb`: emptied required group is an error (DC-9).

## Integration
- `test/cli_init_test.rb`: drives `SoftFoundry::CLI` with `root:` against `with_fixture_repo`, asserting output, exit codes, filesystem state, and `git status`. Uses a copy of the repository's own `.ai/` as the packaged source through an injectable `source:` so tests never depend on an installed gem.

## Acceptance criteria coverage
| Criterion | Test layer | Planned test |
| --- | --- | --- |
| AC-001 | integration | `test_clean_install_installs_canonical_set_and_manifest` |
| AC-002 | integration | `test_refuses_non_git_target_without_flag` |
| AC-003 | integration | `test_second_run_skips_everything_and_leaves_tree_clean` (asserts mtimes) |
| AC-004 | unit + integration | `test_agents_md_preserved_and_marker_appended_once` |
| AC-005 | unit + integration | `test_claude_md_preserved_and_pointer_appended_once` |
| AC-006 | integration | `test_user_edited_rule_is_conflict_and_exit_3` |
| AC-007 | integration | `test_force_overwrites_conflict_and_updates_manifest` |
| AC-008 | integration | `test_preexisting_ai_without_manifest_skips_identical_conflicts_different` |
| AC-009 | integration | `test_gitignore_already_effective_is_skipped` (uses `git check-ignore`) |
| AC-010 | integration | `test_repository_yml_is_unassessed_and_harness_evals_has_only_readme` |
| AC-011 | integration | `test_docs_user_not_created_when_docs_exists_without_user` |
| AC-012 | integration | `test_dry_run_matches_real_report_and_writes_nothing` |
| AC-013 | integration | `test_missing_packaged_workflow_is_internal_error_exit_4_with_upstream_guidance` |
| AC-014 | integration | `test_symlinked_ai_outside_root_is_refused_exit_1` |
| AC-015 | integration | `test_init_runs_onboarding_and_provider_errors_do_not_fail` (env cleared) |
| AC-016 | integration | `test_report_is_readable_after_stripping_non_ascii` |
| AC-017 | unit | `test_gemspec_declares_ruby_32_and_packages_scaffolding` |

## Threat-driven tests (mitigations with attack_case_required)
| Mitigation | Planned test |
| --- | --- |
| MIT-001 | internal symlink under `.ai/`, symlinked `AGENTS.md`, FIFO at a managed path: all refused, nothing written |
| MIT-002 | packaged entry with `..` or symlink rejected by `Source` |
| MIT-004 | hand-edited manifest claiming a user file: file still `conflict` because content differs from canonical and is uncommitted (DC-1) |
| MIT-005 | manifest entry outside `.ai/`: ignored and warned, never written or deleted |
| MIT-006 | `--force` leaves pointer files, `repository.yml`, `.gitignore` untouched; `--force --allow-non-git` refused |
| MIT-007 | second `init` while lock held exits 1 |
| MIT-008 | `--root ~`-style non-toplevel refused; dash-prefixed root value treated as a path |
| MIT-009 | bare marker line is `conflict` |
| MIT-010 | `check` errors on emptied required group |
| MIT-011 | `.gitignore` with a negation that un-ignores `.soft-foundry/` is `conflict` |
| MIT-012 | diagnostic omits env values and absolute paths (env seeded with a fake key, asserted absent) |
| MIT-013 | write failure mid-apply reports written files and leaves no manifest (injected failing writer) |
| MIT-014 | YAML alias bomb in manifest rejected |
| MIT-015 | model id with newline and ANSI escape rendered sanitized |

## Not covered and why
- Windows line-ending behavior: no Windows CI runner; documented as a known limitation.
- Real gem installation into a fresh Ruby: covered manually in the PR description, not automated in this change.
