# Evaluation Results

Commit SHA: 87d7b8f0e9e6bbf05f765d35d0a4b56af324ec13

Size: `full_route_sweep` (`soft-foundry change size --phase evaluate`: no scope declared, so the whole repository is sized at the largest size). The journeys cover every command this change adds or alters, and EVAL-016 sweeps the app-wide surface in this repository: usage text, `check`, `change status`, `gate all`, `change summary`, `ci`.

Driver: `evidence/journeys-driver.rb`, run against this checkout at 87d7b8f0e9e6 with provider keys unset, using throwaway repositories. Two driver defects were corrected before the final run of EVAL-016 and EVAL-018 (no expectation was changed): `--help` exits 1 on this branch and on the pre-change gem alike, so the check is that it lists `phase seal`; `change status` takes the slug positionally; the lineage fixture now points `discover` at the repository's first commit, which is older than intake's `commit_sha` (the earlier fixture used a commit sealing now makes equal to it).

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
| EVAL-017 | AC-052 | fail | evidence/EVAL-017-performance.txt |
| EVAL-018 | AC-052 | fail | evidence/EVAL-018-accessibility.txt |
| EVAL-019 | AC-052 | fail | evidence/EVAL-019-git-call-count.txt |

EVAL-001 to EVAL-016: all assertions pass. EVAL-017, EVAL-018 and EVAL-019 fail.

## Failures
1. **EVAL-017 / EVAL-019 (AC-052 timing clause, REQ-036): `gate all` on this record takes 3.43 s against 1.08 s for the pre-change gem (ratio 3.16; the criterion requires under 2).** Counting git subprocesses with a shim: 220 on this branch, 60 before (79 rev-parse, 40 log, 36 cat-file, 35 show, 21 merge-base, 7 diff, 2 status). REQ-036 allows two `ancestor?` calls per phase and one `rev-parse` for the tip; the observed growth is about 160 calls and is not explained by that allowance. Likely a per-check re-resolution of the same SHAs and tips (the gate calls rev-parse/cat-file/show repeatedly per phase). Not fixed here; evaluation does not change application code. Needs remediation or a recorded decision about the bound.
2. **EVAL-018 (REQ-032): the `commit lineage` failure line has no next action.** It reads: `00-intake recorded f7cddc9629b6, which is not an ancestor of this phase's commit_sha 53fa4039eb72; a phase's commit_sha is the HEAD its outputs describe, which follows its predecessor's`. It names the check and both values with 12-character SHAs, a word outcome and no colour, but it states the rule and not an imperative (for example, redo the phase on a commit that follows 00-intake, then seal it). The other eight accessibility assertions pass.

Also observed, not a failure of this change: the AC-022 fixture as literally written cannot fail (see the note in EVAL-009): a sealed handoff's `commit_sha` precedes its sealing commit, so the sealing commit's parent is where the predecessor's `commit_sha` already is. The journey exercises the intent with an older commit instead.

## Not exercised here
AC-019, AC-048, AC-050, AC-051, AC-053, AC-054 are verification, attack, or documentation criteria (suite, eval cases, docs pages, attack phase); they are not user journeys and are left to those phases.

## Accessibility observations
`surfaces.accessibility: true`. Every command here is terminal text and is operated by keyboard alone: there is no pointer, prompt or interactive screen in the new commands. EVAL-018 piped output (not a TTY) and ran under `NO_COLOR=1`: refusals are one line naming the file, the value found and the next action; the sealed line shows a 12-character SHA while `--json` carries the 40-character value; gate lines carry a word (`pass`/`fail`/`warn`/`skip`) beside the glyph so meaning survives stripping non-ASCII; no ANSI escape appears in any transcript (the driver scans all `EVAL-*.txt`); paths are repository-relative. Failure: the lineage line lacks a next action (above).
