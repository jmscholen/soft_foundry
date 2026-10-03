# Evaluation Plan

## Intent being proven
From any repository, `soft-foundry update --yes` brings the machine's `soft-foundry` up to the latest GitHub release of this repository, and says what to do about that repository's `.ai/`.

## Personas
- The maintainer on this machine, where the gem is installed under asdf's Ruby 3.3.1 and run through a global wrapper.
- A reader of the terminal output.

## Journeys
For each journey record: EVAL ID, requirement IDs, starting state, steps, assertions, evidence, result. Recorded in `journeys.yml`. EVAL-001 to EVAL-004 ran against the real network (`evidence/network-transcript.log`); EVAL-005 to EVAL-007 are the command (`evidence/command-transcript.log`).

## UI walkthrough evidence
No UI. The transcripts are the evidence.

## Accessibility interaction
`surfaces.accessibility` is true for command-line output: each outcome is one line in words naming what to do next (the releases page, `--yes`, `init`); the help entry reads complete with non-ASCII stripped; no prompt.
