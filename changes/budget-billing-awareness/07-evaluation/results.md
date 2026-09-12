# Evaluation Results

Commit SHA: f47178af37dc4e7c9542cb4fe10b29c292029e5b

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | subscription-means-no-budget | pass | evidence/journey-transcript.log |
| EVAL-002 | api-key-applies-policy | pass | evidence/journey-transcript.log |
| EVAL-003 | periodic-warning-on-interval-crossing | pass | evidence/journey-transcript.log |
| EVAL-004 | threshold-adjustable-per-machine | pass | evidence/journey-transcript.log |
| EVAL-005 | colon-title-round-trips | pass | evidence/journey-transcript.log |
| EVAL-006 | override-wins | pass | evidence/journey-transcript.log |

## Failures
None at this commit. The first run of this same journey, against commit `e028173`, failed EVAL-001/EVAL-002's shell step: the fake `claude` launched with no notice above it, because `exec` replaced the process before Ruby's buffered stdout flushed (IMP-2 in 05-implementation/log.md). Fixed in `f47178a` and re-run; the transcript here is from the re-run.

## Accessibility observations
N/A — non-interactive CLI, plain-text output.

## Scope note
Performed directly by the interactive session against a real scratch repository carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process, not a synthetic fixture or a mock.
