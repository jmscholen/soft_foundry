# Implementation Log

## Changes made
- `lib/soft_foundry/updater.rb` (new): `Updater` checks RubyGems' `versions/soft_foundry/latest.json`, compares against `SoftFoundry::VERSION` with `Gem::Version`, and installs via `gem install soft_foundry -v <version>` (argv-only, no shell interpolation) only when asked. Fetcher and installer are both injectable for testing.
- `lib/soft_foundry/cli.rb`: `soft-foundry update [--yes]`. Without `--yes`, reports current/latest and whether an update is available; writes nothing. With `--yes`, installs it. `CLI.new` gained an injectable `updater:` parameter, matching the existing `source:` pattern used to test `Installer` without a real gem environment.
- `README.md` documents the command and the non-interactive confirm idiom.

## Decisions
| Decision | Reason |
| --- | --- |
| No interactive prompt; `--yes` is the confirm step | This CLI has no interactive prompts anywhere; adding one for a single command would be inconsistent. `--yes` matches `--force`/`--dry-run`'s existing idiom. |
| Install version comes from RubyGems' own response, passed as a separate argv element | No shell interpolation, so there is no injection path regardless of what RubyGems returns. |
| No auto-update or background check | Explicit non-goal from intake: an update check is a deliberate action, not a background one, especially for a tool with a `budget` command specifically built to control unattended cost. |

## Deviations from plan
None. No separate planning phase ran for this change (see `00-intake/assumptions.md`).

## Challenges
One real bug found via a live end-to-end run against the actual RubyGems API, not caught by any unit test until added afterward: RubyGems' `latest.json` endpoint does not 404 for a gem with no published version (which `soft_foundry` currently is). It returns HTTP 200 with a literal `{"version":"unknown"}` body. The first draft treated that string as a real version, which `Gem::Version.new` rejected, silently falling back to "no update available" — misleadingly reported as "up to date" when the honest answer is "not published anywhere yet." Fixed to detect the sentinel explicitly and report it as a clear, distinct message, with a regression test.
