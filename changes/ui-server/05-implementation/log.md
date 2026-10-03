# Implementation Log

## Changes made
Plan, as approved by the maintainer for this slice: a hand-rolled loopback server over the snapshot layer, a `ui` command, and a static page with the board and gate views; tests first.

1. RED `0d69a4d`: `test/ui_server_test.rb`, `test/cli_ui_test.rb`, `test/ui_assets_test.rb`.
2. GREEN `93b9422`:
   - `lib/soft_foundry/ui/server.rb` (new): `UI::Server` with `start`, `serve`, `stop`, and `respond(verb, target, headers)`, which holds every routing and refusal decision and touches no socket.
   - `lib/soft_foundry/ui/assets/index.html`, `app.css`, `app.js` (new): the page.
   - `lib/soft_foundry/cli.rb`: the `ui` command, an injectable server factory, help text.
3. Attack phase found two defects (see `09-remediation/summary.md`). RED `ae60e88`, GREEN `5d36e6f`:
   - `UI::Server#admit` evicts the longest-idle connection when every slot is taken.
   - `Snapshot#metadata` refuses a metadata file that is not a mapping, by name.
4. `README.md`: a section on `soft-foundry ui`.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
- A server started in the background of a non-interactive shell script ignores SIGINT, so the evaluation script hung on `kill -INT`. The command's Ctrl-C handling was confirmed by sending SIGINT to a server started directly, and the script uses SIGTERM, which the command handles the same way.
