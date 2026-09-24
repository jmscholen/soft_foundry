# Functional Review

## Scope reviewed
Every requirement in `00-intake/request.md` (REQ-RG-001 to REQ-RG-007) against commit `7306119b`: `Gate#red_evidence_check`, `Git#file_at?`, `Advisory#red_evidence_notices`, the template, rule, and skill text, the documentation, the profile finding, `test/red_green_test.rb`, the RED commit `5d898e0`, and the evaluation transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | minor | `lib/soft_foundry/gate.rb` `red_evidence_check` | "Is the verified commit itself" is decided by prefix comparison of the two hashes, so a short `red_commit` that happens to prefix the full verified hash is treated as equal. Correct for abbreviated hashes of the same commit, and a 7-character collision with a different commit is a non-issue in practice, but a `rev-parse` of both to full hashes would remove the question. Follow-up. | REQ-RG-002 |
| REV-002 | info | `lib/soft_foundry/gate.rb` `red_evidence_check` | The `APP`/`INFRA` change test uses `changed_between(red, green)` committed diff only, which is right: a RED with uncommitted implementation is not GREEN. `TESTS` is excluded on purpose (`decisions.md`). | REQ-RG-002 |
| REV-003 | info | `lib/soft_foundry/advisory.rb` `red_evidence_notices` | Reads `tests.yml` through the advisory's rescuing loader, so an invalid file reads as "no check names a red_commit" and is advised as such while the gate fails it as invalid YAML. Two true statements about one broken file. | REQ-RG-004 |
| REV-004 | info | `06-verification/tests.yml` of this record | CHECK-002 records `result: fail` on purpose: the RED run. The gate does not read `result`, so a retained failure is not a gate failure; the anti-fudging rule about not deleting failed results is honoured by keeping it. | REQ-RG-007 |
| REV-005 | info | the RED commit `5d898e0` | Contains only the test file; eight of nine tests errored there (`evidence/red-at-5d898e0.log`). The two fixes that landed with GREEN touched fixture setup and a call syntax, not expectations; `git diff 5d898e0 7306119 -- test/red_green_test.rb` shows four hunks, none in an assertion. | REQ-RG-007, `.ai/rules/testing.md` |

## Conformance
Conforms. Every requirement is implemented and exercised: REQ-RG-001 by the template and the passing test; REQ-RG-002 by seven tests and EVAL-001 to EVAL-003; REQ-RG-003 by the documentation; REQ-RG-004 by two tests and EVAL-004; REQ-RG-005 by the rule and skill text; REQ-RG-006 by the profile and maturity edits; REQ-RG-007 by this record's own `tests.yml`, the RED run log, and EVAL-005.
