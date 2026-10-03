# Evaluation Plan

## Intent being proven
A person runs one command, opens the URL, and can see where every change stands and why a gate passes or fails, on this repository's real records, without the page being able to change anything.

## Personas
- The maintainer, with twenty-one real records (three open).
- A keyboard-only or screen-reader user of the page.
- A reader of the command's terminal output.

## Journeys
For each journey record: EVAL ID, requirement IDs, starting state, steps, assertions, evidence, result. Recorded in `journeys.yml`.

- EVAL-001 start, serve, stop (REQ-UI-001, REQ-UI-002, REQ-UI-004).
- EVAL-002 refusals (REQ-UI-001).
- EVAL-003 data follows a record edit (REQ-UI-004, REQ-UI-007).
- EVAL-004 the board in a browser (REQ-UI-005).
- EVAL-005 one change, selecting a gate, live update (REQ-UI-006, REQ-UI-007).
- EVAL-006 accessibility of the page (REQ-UI-008).
- EVAL-007 the command's help with non-ASCII stripped (REQ-UI-001).

## UI walkthrough evidence
`evidence/browser-observations.log`: what Chrome showed, taken from the live DOM and screenshots while driving the real page. Screenshots were viewed, not committed; the log records what they showed.

## Accessibility interaction
`surfaces.accessibility` is true. Exercised: keyboard tab order and a real Tab press with the focus indicator measured; focus kept across a live update; the live-region announcement; pause; language, landmarks, headings, table semantics; state words in every cell; contrast computed for both schemes; reflow with the body at 320 CSS px; target sizes. Not exercised: a screen reader, the light scheme on screen, 200% zoom, a real 320 px viewport.
