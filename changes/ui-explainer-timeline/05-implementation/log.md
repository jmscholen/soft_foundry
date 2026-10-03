# Implementation Log

## Changes made
1. RED `8ca41db`: two failing tests in `test/snapshot_test.rb` (unusable times, over-cap flags), two in `test/ui_assets_test.rb` (workflow link and headings, pause stops animation), and one characterization test that already passed (every phase's checks are listed).
2. GREEN `ab1723b`:
   - `lib/soft_foundry/snapshot.rb`: the timeline leaves out an event whose recorded time is not a date; spend totals carry `over_cap` and `needs_approval`, each phase row `over_cap`; the workflow carries `check_descriptions`.
   - `lib/soft_foundry/ui/assets/app.js`: `workflowView`, `phasePanel`, `waysBack`, `timelineSection`, `spendSection`, check descriptions in the gate panel, the `#/workflow[/phase]` route, `data-paused`.
   - `index.html`: the Workflow link. `app.css`: tracks, timeline, spend table, the paused rule, no outline on the heading that receives focus on navigation.
3. `README.md`: two sentences on the new views.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
None substantive.
