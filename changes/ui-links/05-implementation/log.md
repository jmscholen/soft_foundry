# Implementation Log

## Changes made
GREEN `3562625` (no RED commit; see `00-intake/assumptions.md`):
- `app.js`: `gateLink`, `phaseLink`, `changeLink`, `repoLink` make every reference a link carrying `data-ref` and what it refers to; `linkify` turns `NN-name` directory names in free text into gate links; every place that named a change, phase, or repository as text now uses them (34 call sites). A tooltip element, `describeRef` (what the reference points at, from data already on the page), `located` (the path), and the hover, focus, Escape, and navigation handling. Commits in a gate panel are focusable references with a popup. Board flags became links to what they flag; column headers link to the phase in the Workflow.
- `index.html`: the tooltip element.
- `app.css`: flag links, header links, the popup, and the dotted underline for a non-link reference.
- `test/ui_assets_test.rb`: a static test for the link makers, the tooltip, `aria-describedby`, Escape, focus, and the two file names.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
None substantive. The board's column headers were first given links without the popup attributes and showed no popup; found and fixed in the browser pass.
