# Implementation Log

## Changes made
1. RED `83f631c`: additions to `test/ui_server_test.rb`, `test/processes_test.rb`, `test/snapshot_test.rb`, `test/cli_ui_test.rb`, `test/ui_assets_test.rb`.
2. GREEN `952808b`:
   - `lib/soft_foundry/ui/server.rb`: a registry of repositories keyed by issued id; `/api/repositories`; `repo=` on the workflow, changes, and change routes; a per-run token required on every data route; `url`.
   - `lib/soft_foundry/processes.rb`: `snapshot(roots:, with_roots:)` so the server can learn each entry's repository and look for unfinished runs in every known one; the absolute root is otherwise never reported. `Processes.display` is public.
   - `lib/soft_foundry/snapshot.rb`: `overview`, a repository's open changes and counts without gating.
   - `lib/soft_foundry/cli.rb`: `ui --repo PATH` (repeatable); the printed link is the server's `url`.
   - `lib/soft_foundry/ui/assets/`: Repositories as the home page; `#/r/<id>/…` pages with a repository bar; Running links to repositories and changes; the token taken from the link, removed from the address, sent as a header; a page for "no token".
3. `README.md`: the browser section rewritten around repositories and the link.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
- The Running view stopped drawing after the restructure and the page reported "Not connected". The cause was a helper function shadowed by a local variable of the same name inside it; the page's catch-all treated a drawing fault like a network fault and said nothing. The catch now logs the cause to the console. Found in the browser pass against the real machine.
- A link with a token did nothing in a tab that already had the page open, because only the fragment changed and the token was read once at load. It is now read on every navigation.
