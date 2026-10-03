# Implementation Log

## Changes made
1. RED `365382a`: `test/processes_test.rb`, `test/cli_ps_test.rb`, and additions to `test/ui_server_test.rb` and `test/ui_assets_test.rb`.
2. GREEN `0d3a043`:
   - `lib/soft_foundry/processes.rb` (new): `Processes#list` and `#snapshot`, with injectable `ps` and working-directory sources.
   - `lib/soft_foundry/cli.rb`: the `ps` command, an injectable `processes:` factory, help text.
   - `lib/soft_foundry/ui/server.rb`: the `/api/processes` route.
   - `lib/soft_foundry/ui/assets/`: the Running view; running and interrupted flags on the board; "Running now" and interrupted notes and a gate marker on a change; every poll also reads the process list.
3. The maintainer reported that sessions in other terminals were not shown. RED `79e48c2`, GREEN `dd18466`:
   - `Processes#sessions`: coding shells whose working directory is inside a repository with a control plane, with terminal (a new `tty` column from `ps`), branch, change, and the change's recorded phase and status.
   - `ps` prints a `sessions:` section; the Running view has a Sessions table above Commands; the board flags "Session open" and a change says which session is open on it.
4. `README.md`: a paragraph on `ps` and the Running view.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
None substantive. Staging concurrent sessions for evaluation needed stand-in `claude` and `codex` executables that only sleep, started with their real names so the session column is exercised.
