# Evaluation Plan

## Intent being proven
A maintainer who runs onboarding, fresh or repeated, sees what's actually deficient in their repository's maturity, in the terminal and in a file they can come back to — including a repository that was already assessed before this change existed, which is the exact situation that prompted it.

## Personas
A repository maintainer onboarding a new repository, and a maintainer re-running onboarding on a repository someone already assessed.

## Journeys
| ID | Steps | Assertions | Result |
| --- | --- | --- | --- |
| EVAL-001 | `init` a fresh repo (scan mode) | terminal shows level, blocking gaps, deficiency count; `.ai/maturity-report.md` exists with real rationale text | pass |
| EVAL-002 | `init` the same repo again | skip-path message shown, but the SAME summary still prints; report file untouched (byte-identical, mtime unchanged) | pass |

## UI walkthrough evidence
No UI; the CLI's own text output and the persisted markdown file are the interface. `evidence/journey-transcript.log` is the real transcript from a scratch repository.

## Accessibility interaction
Not applicable: non-interactive CLI, plain-text and markdown output, no keyboard-navigation surface.
