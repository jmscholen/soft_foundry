# Evaluation Plan

## Intent being proven
Someone who does not know the lifecycle can read what each gate is for, and someone following a change can see what happened to it and what it cost, on real records.

## Personas
- A newcomer to the repository reading the Workflow view.
- The maintainer following a change's history and spend.
- A keyboard-only user.

## Journeys
For each journey record: EVAL ID, requirement IDs, starting state, steps, assertions, evidence, result. Recorded in `journeys.yml`.

- EVAL-001 the workflow data as served (REQ-UX-001, REQ-UX-003).
- EVAL-002 timeline and spend data for a change built to exercise them (REQ-UX-004, REQ-UX-005).
- EVAL-003 the timeline of a real record (REQ-UX-004).
- EVAL-004 the Workflow view in a browser (REQ-UX-001, REQ-UX-002).
- EVAL-005 checks explained, timeline, and spend in a browser, with hostile text (REQ-UX-003, REQ-UX-004, REQ-UX-005).
- EVAL-006 accessibility of the new parts (REQ-UX-006).

## UI walkthrough evidence
`evidence/browser-observations.log`: what Chrome showed, from the live DOM and screenshots.

## Accessibility interaction
`surfaces.accessibility` is true. Exercised: keyboard selection of a phase with focus kept, words for every state in the new table, table and list semantics, pause stopping the animation, no page overflow. Not exercised: a screen reader, the light scheme on screen, 200% zoom, a 320 px viewport.
