# Evaluation Plan

## Intent being proven
Nothing on the page names a change, phase, repository, or commit without being a link to it, and hovering or focusing any of them says what it is and which file it lives in.

## Personas
- The maintainer, who asked for this, on the real machine.
- A keyboard user.

## Journeys
For each journey record: EVAL ID, requirement IDs, starting state, steps, assertions, evidence, result. Recorded in `journeys.yml`; all in `evidence/browser-observations.log`.

## UI walkthrough evidence
`evidence/browser-observations.log`.

## Accessibility interaction
`surfaces.accessibility` is true. Exercised: keyboard focus opens the popup, `aria-describedby` is set, Escape closes it, `role="tooltip"` on the element. Not exercised: a screen reader, the light scheme, 200% zoom, keeping the popup open under the pointer.
