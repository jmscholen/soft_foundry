# Implementation Log

## Changes made
1. RED `365382a`: `test/processes_test.rb`, `test/cli_ps_test.rb`, and additions to `test/ui_server_test.rb` and `test/ui_assets_test.rb`.
2. GREEN `0d3a043`:
   - `lib/soft_foundry/processes.rb` (new): `Processes#list` and `#snapshot`, with injectable `ps` and working-directory sources.
   - `lib/soft_foundry/cli.rb`: the `ps` command, an injectable `processes:` factory, help text.
   - `lib/soft_foundry/ui/server.rb`: the `/api/processes` route.
   - `lib/soft_foundry/ui/assets/`: the Running view; running and interrupted flags on the board; "Running now" and interrupted notes and a gate marker on a change; every poll also reads the process list.
3. `README.md`: a paragraph on `ps` and the Running view.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
None substantive. Staging concurrent sessions for evaluation needed stand-in `claude` and `codex` executables that only sleep, started with their real names so the session column is exercised.
