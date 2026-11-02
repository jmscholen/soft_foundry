# Evaluation Results

Commit SHA: b871187a6bf28f6e2fc4730920a099c0bde9f580

Size: `full_route_sweep` (`soft-foundry change size --phase evaluate`: no scope declared, so the whole repository is sized at the largest size). The journeys cover every command this change adds or alters, and EVAL-016 sweeps the app-wide surface in this repository: usage text, `check`, `change status`, `gate all`, `change summary`, `ci`.

Driver: `evidence/journeys-driver.rb`, run against this checkout at b871187a6bf2 (the third remediation pass) with provider keys unset, using throwaway repositories and the pre-change gem 0.22.0 for the timing comparison. Every journey was rerun; no expectation was changed from the previous pass.

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | AC-001, AC-005, AC-009 | pass | evidence/EVAL-001-seal-happy-path.txt |
| EVAL-002 | AC-002, AC-003, AC-004 | pass | evidence/EVAL-002-seal-refusals.txt |
| EVAL-003 | AC-006, AC-007, AC-008 | pass | evidence/EVAL-003-seal-staging-and-advance.txt |
| EVAL-004 | AC-010 | pass | evidence/EVAL-004-seal-hook-refusal.txt |
| EVAL-005 | AC-016, AC-017 | pass | evidence/EVAL-005-predecessor-recorded.txt |
| EVAL-006 | AC-011, AC-012, AC-015 | pass | evidence/EVAL-006-runner-seals.txt |
| EVAL-007 | AC-013, AC-014, AC-055 | pass | evidence/EVAL-007-runner-parallel.txt |
| EVAL-008 | AC-018, AC-020, AC-021 | pass | evidence/EVAL-008-structured-files-parse.txt |
| EVAL-009 | AC-022, AC-023, AC-024 | pass | evidence/EVAL-009-commit-lineage.txt |
| EVAL-010 | AC-025, AC-026, AC-027 | pass | evidence/EVAL-010-test-results-recorded.txt |
| EVAL-011 | AC-028, AC-029, AC-030 | pass | evidence/EVAL-011-criteria-covered.txt |
| EVAL-012 | AC-031, AC-032, AC-033 | pass | evidence/EVAL-012-evidence-manifest.txt |
| EVAL-013 | AC-034, AC-035, AC-036, AC-037, AC-038 | pass | evidence/EVAL-013-verdict-and-fresh-session.txt |
| EVAL-014 | AC-039, AC-040, AC-041, AC-042, AC-043 | pass | evidence/EVAL-014-commands.txt |
| EVAL-015 | AC-044, AC-045, AC-046, AC-047, AC-049 | pass | evidence/EVAL-015-residuals.txt |
| EVAL-016 | AC-052 | pass | evidence/EVAL-016-smoke-this-repository.txt |
| EVAL-017 | AC-052 | pass | evidence/EVAL-017-performance.txt |
| EVAL-018 | AC-052 | pass | evidence/EVAL-018-accessibility.txt |
| EVAL-019 | AC-052 | pass | evidence/EVAL-019-git-call-count.txt |

All 19 journeys pass.

## Previous failures, now resolved
1. **EVAL-017 / EVAL-019 (AC-052 timing, REQ-036).** `gate all` on this record: median 1.42 s against 1.18 s for the pre-change gem (three runs each), ratio 1.20 against the bound of under 2 (was 3.16). Git subprocesses counted with a PATH shim: 71 against 64 for the pre-change gem (was 220 against 60).
2. **EVAL-018 (REQ-032).** The `commit lineage` failure line now names the check, the value found and the next action; all nine accessibility assertions pass.

Also observed, not a failure of this change: the AC-022 fixture as literally written cannot fail (a sealed handoff's `commit_sha` precedes its sealing commit); EVAL-009 exercises the intent with an older commit. The specification wording may be tightened.

## Not exercised here
AC-019, AC-048, AC-050, AC-051, AC-053, AC-054 are verification, attack, or documentation criteria (suite, eval cases, docs pages, attack phase); they are not user journeys and are left to those phases.

## Accessibility observations
`surfaces.accessibility: true`. Every command here is terminal text and is operated by keyboard alone: there is no pointer, prompt or interactive screen in the new commands. EVAL-018 piped output (not a TTY) and ran under `NO_COLOR=1`: refusals are one line naming the file, the value found and the next action; the sealed line shows a 12-character SHA while `--json` carries the 40-character value; gate lines carry a word (`pass`/`fail`/`warn`/`skip`) beside the glyph so meaning survives stripping non-ASCII; no ANSI escape appears in any transcript (the driver scans all `EVAL-*.txt`); paths are repository-relative.  The lineage line now carries a next action.
