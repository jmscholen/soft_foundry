# Evaluation Plan

## Intent being proven
A maintainer adopting Soft Foundry sees a real, honest maturity number after onboarding, without paying for it unless they choose to; running onboarding again doesn't repeat the work.

## Personas
A repository maintainer running `soft-foundry init` for the first time on an existing Ruby/Rails application, then running it again later.

## Journeys
| ID | Steps | Assertions | Result |
| --- | --- | --- | --- |
| EVAL-001 | `init` a repo with a Rails/RSpec signature, no IaC | technology and testing detected correctly, infrastructure correctly `NOT_APPLICABLE` (not guessed as missing), a computed level and gap list printed | pass |
| EVAL-002 | `init` the same repo again | maturity step is skipped with a clear message, `.ai/repository.yml` unchanged | pass |
| EVAL-003 | `init --reassess` | re-scans despite prior assessment | pass |

## UI walkthrough evidence
No UI; the CLI's own text output is the interface. `evidence/journey-transcript.log` is the real transcript from a scratch repository, not a fixture or a mock.

## Accessibility interaction
Not applicable: non-interactive CLI, plain-text output, no keyboard-navigation surface.
