# Verification Results

Commit SHA: 459fa860a35924d47b49b12e507543547768d8ef (tree 281dff35a6680a623ba28cf31100362219ca6054). The code it describes is the remediation's GREEN commit b118833. The commit after that only records the remediation.

Check size: `full_at_verify` (no scope declared). All checks ran with the worktree's own `lib/` (`ruby -Ilib exe/soft-foundry`). Provider keys and `SOFT_FOUNDRY_PHASE` were unset.

This is the rerun after remediation round 1 (REV-001: onboarding left the quality gate off in a newly initialized repository).

## Deterministic checks

| Check | Command | Result | Criteria |
| --- | --- | --- | --- |
| CHECK-001 | `ruby -Ilib -Itest test/code_quality_gate_test.rb` | pass: 29 runs, 223 assertions | AC-001 to AC-009, AC-011, AC-012 |
| CHECK-002 | `bundle exec rake test` (full suite) | pass: 980 runs, 7307 assertions, 0 failures, 0 errors, 0 skips | AC-010 |
| CHECK-003 | `test/maturity_scan_test.rb`, `test/cli_init_test.rb` | pass: 11 and 33 runs | AC-010, AC-012 |
| CHECK-004 | `soft-foundry check` | pass: 17 phases, 18 skills, no errors | AC-001 |
| CHECK-005 | `soft-foundry ci` | pass | AC-002, AC-010 |
| CHECK-006 | diff of existing tests, f508df2 to b118833 | pass: no new edits; earlier ones match DEV-004 | AC-010 |
| CHECK-007 | `init --maturity scan` and `onboard` in scratch repositories | pass | AC-012 |

RED evidence: commit `55448aa` adds only the two REV-001 tests to `test/code_quality_gate_test.rb`. This session ran both at that commit, in a temporary worktree it then removed, and both failed with `enabled` false where true was expected. The fix (`b118833`) changes `lib/soft_foundry/maturity_scan.rb` and the comment in `.ai/templates/repository.yml`.

## REV-001 from the outside

Scratch repositories, `soft-foundry init --maturity scan`:
- With a `Gemfile`: `quality_gate` is `enabled: true`, `set_by: soft-foundry (language scan: ruby)`.
- With no scripting language: `enabled: false`, set by the scan.
- With a person's `enabled: false` and a name in `set_by`, `soft-foundry onboard` keeps it.

## Failures

None.

## Evidence

Listed in `evidence/manifest.yml` with SHA-256 digests.

## Coverage notes

- AC-008 is still covered only by structure. No test drives a third remediation round after a blocking quality finding (VER-001, carried forward).
- AC-005, AC-009 and AC-011 are text criteria. The test file checks them by reading the skill, the documentation and the help output.
- A `set_by` holding only whitespace counts as unset (`strip` in `set_by_a_person?`). This was read in the code, and no test covers it.

Evidence generated for a different implementation commit is stale.
