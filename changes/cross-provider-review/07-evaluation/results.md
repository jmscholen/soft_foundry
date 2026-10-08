# Evaluation Results

Commit SHA: a963a27e4fc34e5200aa212bbc9d51d67e293cd1

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-XP-003 | pass | evidence/journey-transcript.log |
| EVAL-002 | REQ-XP-003 | pass | evidence/journey-transcript.log |
| EVAL-003 | REQ-XP-002, REQ-XP-003 | pass | evidence/journey-transcript.log |
| EVAL-004 | REQ-XP-004, REQ-XP-005 | pass | evidence/journey-transcript.log |
| EVAL-005 | REQ-XP-003 | pass | evidence/journey-transcript.log |
| EVAL-006 | REQ-XP-003 | pass | evidence/journey-transcript.log |

Third run, after remediations REM-001 and REM-002, with EVAL-006 added for REV-FUN-001 (codex is chosen and the missing remediation provider is named); the journeys and outcomes are the same as at 0370e02, with the gate's wording now "above minor".

## Failures
None. The evidence was regenerated once: the first script ran EVAL-005 after EVAL-004 had completed the review, so `phase run` refused and printed nothing; the script was reordered and every journey rerun.

Observation (EVAL-OBS-001): on this machine the default for a Claude-implemented change is Codex, whose login has expired; a real `phase run review` without `--shell` would start Codex and fail. The maintainer has paused Codex testing; until its login is renewed, `--shell grok` is the way to run review here. This is the non-goal recorded in intake.

## Accessibility observations
The `shell:` and `! warn shell:` lines and the gate's `findings explained` line carry status words and read unchanged with non-ASCII bytes deleted. No new prompts, colors, or glyph-only meaning.
