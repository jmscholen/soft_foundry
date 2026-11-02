# Evaluation Plan

## Intent being proven
After `gate-hardening`, a maintainer sees a passing gate and knows the record's evidence parses, its commits descend in order, its failing tests are named, its criteria are covered or set aside, its manifest matches, its verdict is one of four words, and every phase was committed by the tool (`phase seal`), not by hand. This phase proves it by using the commands the way each persona would, against throwaway repositories and this checkout. Size: `full_route_sweep`.

## Personas
- Phase session: seals its own phase, is refused when the handoff is incomplete, code is dirty or the gate fails.
- Runner (`phase run`, `--parallel`): seals what a fresh session completed, in lifecycle order.
- Maintainer: `gate`, `change close`, `change new --flag=value`, `change summary`, `phase reopen`, `ci`.
- CI / pre-commit hook: reads records, never re-gates closed ones.

## Journeys
EVAL-001 to EVAL-004 sealing; EVAL-005 recorded predecessor; EVAL-006 and EVAL-007 runner; EVAL-008 to EVAL-013 the seven new checks; EVAL-014 commands; EVAL-015 residuals; EVAL-016 app-wide smoke in this repository; EVAL-017 and EVAL-019 timing and git-call count (AC-052, REQ-036); EVAL-018 accessibility (REQ-032). Each maps to acceptance criteria in `journeys.yml`; each transcript in `evidence/` records every command, its output, exit code and assertions. Results are in `results.md`.

## UI walkthrough evidence
No UI changed: the surface is the command line, so transcripts stand in for screenshots.

## Accessibility interaction
`surfaces.accessibility` is true. Keyboard-only operation (the commands are non-interactive), no colour reliance (`NO_COLOR=1`, piped output), one-line refusals, word outcomes beside glyphs, repository-relative paths and 12-character SHAs were exercised in EVAL-018.
