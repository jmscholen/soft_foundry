# Evaluation Plan

## Intent being proven
With several Soft Foundry sessions running at once in different repositories, a person can see all of them, tell which belong to the repository in front of them, and notice one that died.

## Personas
- The maintainer running phase sessions in more than one project.
- A reader of the terminal output of `soft-foundry ps`.
- A keyboard user of the page at a narrow width.

## Journeys
For each journey record: EVAL ID, requirement IDs, starting state, steps, assertions, evidence, result. Recorded in `journeys.yml`. The sessions are real `soft-foundry phase run` processes in two scratch repositories whose `claude` and `codex` are stand-ins that sleep.

- EVAL-001 `ps` from a repository with its own session (REQ-PS-001, REQ-PS-003, REQ-PS-004, REQ-PS-005).
- EVAL-002 `ps` from an unrelated directory (REQ-PS-001).
- EVAL-003 the data the page reads (REQ-PS-001, REQ-PS-002).
- EVAL-004 a killed session becomes an interrupted run (REQ-PS-004).
- EVAL-005 `ps` output with non-ASCII stripped (REQ-PS-008).
- EVAL-006 the Running view in a browser (REQ-PS-007, REQ-PS-008).
- EVAL-007 the board and a change say what is running (REQ-PS-007).
- EVAL-008 the page follows a session dying (REQ-PS-007).

## UI walkthrough evidence
`evidence/browser-observations.log`.

## Accessibility interaction
`surfaces.accessibility` is true. Exercised: table semantics, state in words, a link per change in this repository, no sideways page scroll at 614 CSS px, the command's lines with non-ASCII stripped. Not exercised: a screen reader, the light scheme, 200% zoom.
