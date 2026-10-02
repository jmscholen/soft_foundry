# Change Intake

## User intent
Third of the three changes the maintainer approved toward "a user interface to better understand each gate visually and understand what is going on": the two remaining views, a workflow explainer and each change's timeline and spend, on the page `soft-foundry ui` already serves.

## Desired outcome
- REQ-UX-001: a Workflow view shows the lifecycle from `.ai/workflow.yml`: every phase in order, marked required or optional; for a selected phase its skill, directory, model profile, what follows it, where it can return to, every check its gate runs with a one-line description, the files it must produce, and its blocking conditions. The selected phase is addressable by URL.
- REQ-UX-002: the Workflow view lists the moves that leave the listed order with their conditions, the tracks (default, exploring stage, what a vet requires, what is not required first, which risk forces which track), and the judgments.
- REQ-UX-003: in a change, each check is shown with what it establishes, in the workflow's own words.
- REQ-UX-004: a change shows its timeline, oldest first, from recorded times only, and says the times are as recorded. An event whose recorded time is not a date is left out (ui-snapshot REV-002).
- REQ-UX-005: a change shows its spend: total, tokens, entries without a cost, the budget caps for its risk, a per-phase table, and in words whether a phase or the change is over its cap or above the approval line. No ledger is an invitation to record one.
- REQ-UX-006 (accessibility, WCAG 2.2 AA): the new views keep the page's floor: words for every state (1.4.1), keyboard operation and focus retention (2.1.1, 2.4.7), headings and table semantics (1.3.1), and pausing updates also stops the page's one animation (2.2.2; ui-server REV-024).
- REQ-UX-007: every phase's listed checks cover what its gate runs (ui-snapshot REV-004).

## Constraints
- No new route, no new dependency, no write path. One new field in the workflow data (`check_descriptions`) and three in the spend data (`over_cap`, `needs_approval`).
- Record text is rendered as text only, as in ui-server.

## Non-goals
- No drawn graph of the lifecycle: the loops are stated in words and on each phase.
- No close event on the timeline (no `closed_at` is recorded), no git-history timeline.
- The gate strip's disclosure pattern (ui-server REV-023) and a more specific live announcement (REV-025) wait for a screen-reader pass.

## Task classification
feature

## Initial risk
low. Page-only additions over existing read-only routes, plus two small data-layer changes with tests.
