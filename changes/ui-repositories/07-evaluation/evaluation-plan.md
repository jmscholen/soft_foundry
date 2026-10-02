# Evaluation Plan

## Intent being proven
The page has one flow a person can follow: which repositories have something going on, into one of them, to its changes and gates, and from anything running to where it is. And only someone given the link can read any of it.

## Personas
- The maintainer, with five sessions open in four repositories: the person who said the earlier flow made no sense.
- A program holding the link, and one without it.
- A keyboard user at a narrow width.

## Journeys
For each journey record: EVAL ID, requirement IDs, starting state, steps, assertions, evidence, result. Recorded in `journeys.yml`. EVAL-001 to EVAL-005 use staged scratch repositories so they can be written down; EVAL-006 to EVAL-010 are the real machine in a browser, with other repositories' names left out.

## UI walkthrough evidence
`evidence/browser-observations.log`.

## Accessibility interaction
`surfaces.accessibility` is true. Exercised: titles per page naming the repository, the repository bar as a labelled landmark with the current tab marked, heading structure of the cards, words for every state, the token refusal explained in text, no sideways page scroll at 614 px across all five kinds of page. Not exercised: a screen reader, the light scheme, 200% zoom.
