# Implementation Log

## Commits (in order)
1. `fee41bb` — Adds `Git#default_branch`/`#ancestor?`, `ChangeRecord#last_commit_sha`/`#commit_sha_at_judgment`/`#judgment_evidence`/`#undischarged_acceptance`/`#discharge!`/`#close!`, the new `PrDischarge` class, the CLI's `change close`/`change request-discharge` subcommands and `ci`'s new merged-but-not-closed check, the formalized `undischarged`/`discharged` fields in `.ai/skills/final-judgment/template/evidence.yml`, and the README section documenting closure.
2. `ce5230c` — Regression coverage: `test/git_test.rb`, new tests in `test/change_record_test.rb`, `test/pr_discharge_test.rb`, and `test/cli_change_close_test.rb` (full CLI-level coverage of `close`/`request-discharge`/`ci`'s new check, including the false-positive regression below).
3. `9f6ecfc` — Version bump to 0.5.0, matching this repo's existing minor-bump-per-merged-change pattern.

## A real bug found before shipping
The first version of the "merged but not closed" check used `ChangeRecord#last_commit_sha` (whatever the most-recently-completed phase's commit is). Running `soft-foundry ci` against this repository's own history immediately flagged `changes/upstream-failure-reporting` as "merged but not closed" — a false positive. That change never got past intake (`status: in_progress`, `current_phase: discover`); its intake commit is simply the commit history had already reached when intake was recorded, which is trivially an ancestor of the current default branch the same way any branch's fork point is. The check was conflating "this commit is old enough to be in main's history" with "this change's work merged."

Fixed by adding `ChangeRecord#commit_sha_at_judgment`, which only returns a commit once the change has actually reached `judge` or `learn` — the point where "this commit is an ancestor of main" starts meaning something real. `ci` and `change close` both switched to it. Re-running `ci` against this repository afterward showed `upstream-failure-reporting` correctly ignored, and a dedicated regression test (`test_ci_does_not_flag_an_early_abandoned_change_as_merged`) locks the behavior in.

## Why PrDischarge takes injectable fetcher/poster
Mirrors `Updater`'s existing `@fetcher`/`@installer` pattern (see `lib/soft_foundry/updater.rb`) so `gh` is never actually shelled out to in tests — `PrDischarge.new(root, fetcher:, poster:)` and `CLI.new(..., pr_discharge:)` let tests inject fakes and assert on exactly what would have been posted/parsed.
