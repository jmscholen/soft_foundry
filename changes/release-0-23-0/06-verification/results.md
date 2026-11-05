# Verification Results

Commit SHA: f6d6dc23e8e3624a45e397ac579d5c416260acaa
Tree: 3c50e183e994853d3f0ff581bd02c39fc64e005f

## Deterministic checks
Size: `full_at_verify` (`soft-foundry change size --phase verify`; no scope declared).

| Check | Command | Result |
| --- | --- | --- |
| CHECK-001 | `bundle exec rake test`, provider keys and `SOFT_FOUNDRY_*` unset, run alone | pass: 902 runs, 6653 assertions, 0 failures, 0 errors, 0 skips |
| CHECK-002 | `soft-foundry check` | pass: 16 phases, 17 skills, no errors |
| CHECK-003 | `soft-foundry eval` | pass: 28 passed, 0 failed, 0 errors, 1 skipped (the live case) |
| CHECK-004 | `soft-foundry ci` | pass |
| CHECK-005 | `soft-foundry version` | pass: prints 0.23.0 |
| CHECK-006 | `gem build`, into a temporary directory removed afterwards | pass: built soft_foundry 0.23.0; warns of no license and no homepage |
| CHECK-007 | `git diff main` and `git status --short`, excluding this record | pass: only `lib/soft_foundry/version.rb` differs, 0.22.0 to 0.23.0 |

Linters, static analysis, security scanners, IaC validation and migrations: the repository's CI defines none, so none ran.

The checks ran from the local library (`ruby -Ilib exe/soft-foundry`), not the installed gem. The tag workflow itself was not run; CHECK-005 and CHECK-006 run its version and build commands locally.

## Failures
None.

## Evidence
Under `evidence/`, listed with digests in `evidence/manifest.yml`. No check has a `red_commit`: this is a chore with no failing test first. The specify phase is waived, so no check names acceptance criteria.

Evidence generated for a different implementation commit is stale.
