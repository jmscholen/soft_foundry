# Evaluation Results

Commit SHA: 142baec75fd21d3f0e1bed73d50bf18fddafe719

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | maturity-scan-detection | pass | evidence/journey-transcript.log |
| EVAL-002 | skip-when-assessed | pass | evidence/journey-transcript.log |
| EVAL-003 | reassess-override | pass | evidence/journey-transcript.log |

## Failures
None.

## Accessibility observations
N/A — non-interactive CLI, plain-text output.

## Scope note
Performed directly by the interactive session against a real scratch repository, not a fresh-context agent. `deep` mode was not exercised in a live journey (no real `claude` invocation), only through unit tests with an injectable runner; see `06-verification/results.md`'s scope note.
