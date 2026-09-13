# Evaluation Results

Commit SHA: 7db258e3c55a1dd5a6b3a43d9e9738e119e7302b

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
None at this commit. The first run of this same journey, against commit `e028173`, failed EVAL-001/EVAL-002's shell step: the fake `claude` launched with no notice above it, because `exec` replaced the process before Ruby's buffered stdout flushed (IMP-2 in 05-implementation/log.md). Fixed in `f47178a` and re-run. The transcript here is from a further re-run at `c48e867` after IMP-3 and IMP-4, both test-only fixes; the journey output is unchanged.

## Accessibility observations
N/A — non-interactive CLI, plain-text output.

## Scope note
Performed directly by the interactive session against a real scratch repository carrying this repository's actual `.ai/` control plane and the real CLI executable as a separate process, not a synthetic fixture or a mock.
