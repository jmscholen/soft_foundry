# Evaluation Plan

## Intent being proven
A maintainer can declare a per-change scope and a repository shared core and get evidence staleness, full-suite reuse and check sizing that follow the declarations, while a record with no declaration behaves exactly as before. A passing gate never claims a suite passed. Size computed by `soft-foundry change size --phase evaluate` for this record: `full_route_sweep` (no scope is declared on this record, so the whole repository is sized full). Every command and the browser data route below was therefore exercised, not only the ones this diff touches.

## Personas
- Maintainer: declares `scope` in `metadata.yml` and `shared_core` / `access_control` in `.ai/repository.yml`, runs `check`, `change size`, `gate`, `change status`.
- Implementing agent session: records `size` and `full_suite` in `tests.yml`, cites another record's run.
- Reader of the browser view (`soft-foundry ui`): reads scope and staleness.
- Person using a screen reader or `NO_COLOR` terminal: reads the CLI output.

## Journeys
EVAL-001 to EVAL-012 in `journeys.yml`, each mapped to acceptance criteria. Each runs the real checkout (`ruby -Ilib exe/soft-foundry`) in throwaway git repositories built by `evidence/journeys.rb` and `evidence/journeys2.rb` (a copy of this checkout's `.ai/`, directories lib/a, lib/b, lib/base, lib/other, lib/auth, shared core lib/base/**, access control lib/auth/**). Transcripts: `evidence/transcript.txt`, `evidence/transcript2.txt`.

## UI walkthrough evidence
The only UI is the read-only loopback page. No graphical browser was driven in this session; the equivalent evidence is the page's data route (`/api/change`, token header) and the served `app.js` source, which is where scope and state words are rendered. That is weaker than a screenshot and is recorded as such in `results.md`.

## Accessibility interaction
`surfaces.accessibility` is true. Exercised: CLI output captured with `NO_COLOR=1`, ASCII-only stripping, one fact per prefixed line, no prompts (every command ran non-interactively with stdin closed to a pipe), error messages naming the fix. Keyboard operation and focus order of the browser page were not exercised (no browser driven); see results.md.
