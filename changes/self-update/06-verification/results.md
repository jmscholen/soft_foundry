# Verification Results

Commit SHA: 7072fde240846e81bcb4d59e4805fab85f4bf7b8 (bound after commit; see handoff.yml)

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite | `ruby -Ilib -Itest -e '...'` | 135 runs, 946 assertions, 0 failures, 0 errors |
| Control-plane lint | `soft-foundry check` | 16 phases, 16 skills, no errors |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/**/*.rb` and `exe/soft-foundry` | 23 files, Syntax OK, zero warnings |
| Real end-to-end, live RubyGems API | installed gem, real network call, no mock | see `evidence/e2e-smoke.log` |

## Failures
None. One real bug (RubyGems' HTTP-200-with-"unknown" sentinel for an unpublished gem) was found by the live end-to-end run, fixed, and covered by a regression test before this verification pass; see `05-implementation/log.md`.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/e2e-smoke.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per the lighter-weight process recorded in `00-intake/assumptions.md`. The `--yes` install path was verified with an injected installer (no real `gem install` was run against a hypothetical newer version, since none is published to test against).

Evidence generated for a different implementation commit is stale.
