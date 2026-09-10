# Verification Results

Commit SHA: 2afb194f62e2a7d5a1078f0466efa01a09840095 (bound after commit; see handoff.yml)

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { require }'` | 96 runs, 822 assertions, 0 failures, 0 errors |
| Control-plane lint | `soft-foundry check` | 16 phases, 16 skills, no errors |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/**/*.rb` and `exe/soft-foundry` | Syntax OK, zero warnings |
| End-to-end install + budget round-trip | fresh scratch git repo, Ruby 3.3.1 | see `evidence/e2e-smoke.log` |
| Below-floor Ruby guard | Ruby 2.7.8 binary against this working tree | plain message, exit 1, no raw `SyntaxError` (closes init-command's VER-004) |
| `ci` closed-change skip | `soft-foundry ci` in this repo | `init-command (closed, skipped)`; no stale-evidence failure |

## Failures
None.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/e2e-smoke.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per the lighter-weight process recorded in `00-intake/assumptions.md`. The over-cap (`exit 2`) path was exercised by the automated test suite (`CLIInitTest#test_status_reports_over_cap_with_exit_2`) rather than repeated manually here; both are the same code path.

Evidence generated for a different implementation commit is stale.
