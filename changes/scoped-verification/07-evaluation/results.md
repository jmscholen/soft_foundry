# Evaluation Results

Commit SHA: ea50ad589eb0ac2d3a61a5899b1ad9d23029757d

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
| EVAL-013 status of a current scoped record when another record's code lands | AC-018 | pass (failed before remediation; still repaired at this commit) | transcript2.txt |

AC-006 (specification re-record cause, stacked-branch base) and AC-021/AC-022 (suite, evals, dependency, git-call count) were not re-exercised by hand: verification ran them (625 runs, check, ci, evals) and evaluation did not repeat them. AC-006 is not claimed here.

## Failures
None at this commit. The rerun follows remediation (rename detection, branch-tip check, claimed paths no longer enlarging verify size, exact citation slug, size failure cause). EVAL-F-001 (claimed path made a current scoped record fail its size check and status) no longer reproduces: with A current and code landed under lib/b/, A's gate passes, size stays `targeted_plus_full_before_merge`, status shows `06-verification complete ok`, `phase run verify --change a` refuses as already complete, and an advisory names `lib/b/new.rb` as outside the scope. EVAL-F-002 is repaired: the empty-list size line now says "no changed code path is the cause; the diff base or a declaration is".

Not exercised by hand: a rename journey (remediation's rename and branch-tip changes are covered by regression tests that verification ran, not by a driven journey here), and the unscoped branch-lacking-evidence stale case. The corrupt-evidence journey (EVAL-009) shows the unknown commit failing closed.

## Accessibility observations
CLI: with NO_COLOR=1 and stdin not a terminal, no command prompted. After removing 112 non-ASCII glyphs, 164 outcome words (pass, fail, skip, warn) and 57 prefixed fact lines (`scope:`, `reason:`, `base:`, `size:`, `phase:`) remain; error messages name the next step (for example "declare a path that exists or remove it", "run the full suite on this tree and record it in tests.yml"). Browser: scope is rendered as the text `Scope: <globs>` and gate state as words (`Stale`, `Fail`, `Pass`) in `app.js` and returned as words by `/api/change`. Not exercised: keyboard-only operation, focus order and screen-reader names of the browser page, because no browser was driven here; the accessibility review must cover them.

## Rerun at ea50ad5 (after REV-001/REV-002 remediation)
Both drivers were run again unchanged against HEAD 916ff15 (after the ATTACK-F-006 remediation of `git.branch` repoint). Normalised for session ids and ports the transcripts match the 2fdd159 run line for line, so EVAL-001 to EVAL-013 hold. The `git.branch` repoint case itself was not driven as a journey here; the regression test added in the remediation covers it and verification ran it.

Rerun at ea50ad5: the drivers were run unchanged (hashes in evidence/manifest.yml unchanged for the .rb files) against HEAD ea50ad5, which adds the REV-001/REV-002 changes to lib/soft_foundry/gate.rb and scope.rb and to the shipped sizing policy. Compared with the 916ff15 transcripts with commit and tree hashes masked, outcomes, exit codes and message wording are identical, so EVAL-001 to EVAL-013 hold; no journey failed. Journeys were not extended to the specific REV-001/REV-002 cases; those are covered by the regression tests verification ran, and I did not drive them by hand. Browser, keyboard and screen-reader checks remain unexercised (EVAL-F-002).
