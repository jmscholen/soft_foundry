# Evaluation Results

Commit SHA: 1bf54b272eadc61c0770944edabe80f744fd71a3

Size: `full_route_sweep` (`soft-foundry change size --phase evaluate`; this record declares no scope, so the whole repository is sized full). Evidence is the real checkout driven through `evidence/journeys.rb` and `evidence/journeys2.rb`; the transcripts are `evidence/transcript.txt` and `evidence/transcript2.txt`. Code paths were clean (only the runner's metadata edits to this change's handoff and metadata were dirty).

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 unscoped and empty-scope records behave alike | AC-001 | pass | transcript.txt |
| EVAL-002 own-scope change stales A, not B | AC-002, AC-005 | pass | transcript.txt |
| EVAL-003 unclaimed and shared-core causes | AC-003, AC-004 | pass | transcript.txt |
| EVAL-004 narrowing the scope stales the evidence | AC-007 | pass | transcript.txt |
| EVAL-005 full-suite record and citation, six refusals | AC-008, AC-009 | pass | transcript2.txt |
| EVAL-006 wording says record, not a test result | AC-010 | pass | transcript2.txt |
| EVAL-007 sizing for verify, evaluate and attack, branch tip, smaller-size refusal | AC-011, AC-012, AC-013, AC-014 | pass | transcript.txt, transcript2.txt |
| EVAL-008 malformed declarations refused by check | AC-015 | pass | transcript.txt |
| EVAL-009 unknown evidence commit fails closed | AC-016 | pass | transcript.txt |
| EVAL-010 advisories print without blocking; phase run refuses a current record | AC-017 | pass | transcript.txt, transcript2.txt |
| EVAL-011 NO_COLOR, ASCII-stripped, fact-per-line output | AC-019 | pass | transcript.txt |
| EVAL-012 browser data shows scope and state words | AC-020 | pass (data route and script source only) | transcript2.txt |
| EVAL-013 status of a current scoped record when another record's code lands | AC-018 | fail | transcript2.txt |

AC-006 (specification re-record cause, stacked-branch base) and AC-021/AC-022 (suite, evals, dependency, git-call count) were not re-exercised by hand: verification ran them (625 runs, check, ci, evals) and evaluation did not repeat them. AC-006 is not claimed here.

## Failures
EVAL-F-001 (AC-018, moderate). Scoped record A has current evidence, a recorded `size: targeted_plus_full_before_merge` and a passed `full_suite`. Code under `lib/b/` (claimed by record B) is then committed on the same branch. `gate verify --change a` still passes "evidence current" and `phase run verify --change a` correctly refuses ("already complete"), but "check size matches diff" now fails (`recorded size targeted_plus_full_before_merge is smaller than computed size full_at_verify (lib/b/new.rb: claimed by another record (b))`) and `change status a` prints `06-verification complete FAIL: check size matches diff`. A is therefore not shown as current, and a person is told to run full_at_verify for a path another record owns. The sizing reading (IMPL-004: one record per branch) makes this unreachable only when each record lives on its own branch; the spec's AC-018 wording does not say that. Either the criterion is narrowed to the one-record-per-branch case or sizing should not count paths claimed by another record. That is a decision for remediation/review, not for evaluation.

Minor: when the evidence commit is unknown, the size failure prints an empty reason list, `computed size is targeted_plus_full_before_merge ()`; the cause is named on the earlier `commit_sha recorded` and `evidence current` lines, so it fails closed.

## Accessibility observations
CLI: with NO_COLOR=1 and stdin not a terminal, no command prompted. After removing 112 non-ASCII glyphs, 164 outcome words (pass, fail, skip, warn) and 57 prefixed fact lines (`scope:`, `reason:`, `base:`, `size:`, `phase:`) remain; error messages name the next step (for example "declare a path that exists or remove it", "run the full suite on this tree and record it in tests.yml"). Browser: scope is rendered as the text `Scope: <globs>` and gate state as words (`Stale`, `Fail`, `Pass`) in `app.js` and returned as words by `/api/change`. Not exercised: keyboard-only operation, focus order and screen-reader names of the browser page, because no browser was driven here; the accessibility review must cover them.
