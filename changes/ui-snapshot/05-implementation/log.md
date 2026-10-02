# Implementation Log

## Changes made
Plan, as approved by the maintainer for this slice: a delivery-neutral data layer, then `--json` on two commands, tests first.

1. RED `594de77`: `test/change_index_test.rb`, `test/snapshot_test.rb`, `test/cli_change_json_test.rb`.
2. GREEN `684fe7d`:
   - `lib/soft_foundry/change_index.rb` (new): `slugs`, `record(slug)`, `default_branch` (memoised), `merged_unclosed?(record)`.
   - `lib/soft_foundry/snapshot.rb` (new): `workflow`, `board`, `change(slug)`, and the class helpers `track`, `stamp`, `plain`.
   - `lib/soft_foundry/gate.rb`: `Gate::CHECKS` (a description per check name) and `Gate.checks_for(plane, phase)`; requires `change_record` because the descriptions name `ChangeRecord::STATUSES`.
   - `lib/soft_foundry/cli.rb`: `change list --json`, `change status [slug] --json`, `status_json`; `track_line` now formats `Snapshot.track`; `ci`, `load_record`, and `list_changes` delegate to `ChangeIndex`; help text.
3. `README.md`: one paragraph on `--json`.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
None substantive. Three test expectations written at RED were wrong about existing behaviour and were corrected at GREEN; recorded in `deviations.md`.
