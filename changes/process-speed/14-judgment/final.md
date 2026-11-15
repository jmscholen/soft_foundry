# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

The twelve must criteria hold on the cases they name. Review's open findings are residual risk. Jeff Scholen recorded on 2026-11-14 that REV-001, REV-002, and REV-003 go to the guard follow-up, that REV-004 and REV-005 go to the next change, and that this change runs no remediation round.

## Commit judged
`ea2c20aa89febc98db05fffd6eb17d2ad2962a19` (`Record process-speed review`). `lib/`, `exe/`, `test/`, `.ai/`, `docs/`, and `README.md` are identical from the implementation commit `a37d5805d4d62bc79b36c45bf275f906912c237a` through this commit. Verification, evaluation, attack, and review describe this code.

This record has no `rules: 2`. It is legacy. The checks this change adds skip it with "legacy record". The judgment below is about what the code does to a record that does declare the rules.

## Requirements status
Must criteria, each met on the case it names:

| Criterion | Evidence |
| --- | --- |
| AC-001 | CHECK-002, CHECK-006, EVAL-014. `change new` writes the rules version. On readme-workflow-visuals the new checks skip and the phase outcomes stay the same. |
| AC-002 | CHECK-002, CHECK-003, EVAL-004. Two sealed rounds, rules present: reopen exits non-zero, handoffs stay, status becomes `awaiting_human`, and the output names the three decisions. |
| AC-004 | CHECK-002, EVAL-006. Review and judgment fail above the cap with no decision, pass that check with a decision at `rounds: 2`, and one further reopen is permitted. |
| AC-005 | CHECK-002, EVAL-001. A missing tier and tier `maybe` fail the specify gate. |
| AC-006 | CHECK-002, EVAL-002. Four must criteria at low risk fail; three pass. |
| AC-007 | CHECK-002, EVAL-003. No approval, and an approval of only AC-001, fail and refuse the specify seal. An approval of exactly AC-001 and AC-002 passes. |
| AC-008 | CHECK-002, EVAL-007. An uncovered should criterion warns. An uncovered must criterion fails. |
| AC-009 | CHECK-002, EVAL-008. Person checks are not criteria. `change release` carries one item each. |
| AC-010 | CHECK-002, EVAL-009. An empty `blocked_by`, a should id, and an `outside_change` finding fail. An unmet must id passes the basis check. |
| AC-015 | CHECK-002, EVAL-011. After a documentation-only reopen, a `lib/` change refuses the remediation seal and names the path. A README-only change seals. |
| AC-017 | CHECK-005, CHECK-007. All six new checks have a `Gate::CHECKS` entry and a passing harness-eval gate case. See REV-010 for the documentation name of `rules kept`. |
| AC-018 | CHECK-001, CHECK-004, CHECK-005, EVAL-014, EVAL-015. Full suite 935 runs, 0 failures. `soft-foundry ci` passes. Legacy phase outcomes unchanged. |

Should criteria are covered by name and passed their journeys, with three recorded gaps. AC-003 passes on the reachable path (a stale verify), which is DEV-001. AC-012's then-clause still lists specify among the default waivers; DEV-004, the maintainer's decision on 2026-11-13, keeps specify required, and the test asserts that. AC-013 and AC-014 pass. AC-016 passes except the attack skill does not say that findings outside the must list are advisory (REV-009). AC-019 passes for the cap refusal under `NO_COLOR` with non-ASCII stripped; the line is 506 characters (REV-012) and a second reopen while parked omits the three decisions (REV-014).

The specification says each criterion holds the change only to the case it names. The inputs in REV-001 through REV-005 are outside those cases. They are residual risk, listed in `residual-risk.md`.

Deviations DEV-001, DEV-002, and DEV-003 match the requirements. DEV-002 warns on an unclassified risk and applies no cap. DEV-003 plants tiers and an approval on harness fixtures.

Person check PC-001 (one real change under the new rules after merge) is not a criterion. `change release` copies it as a release item. It is not left in `undischarged`.

## Verification
Complete at `9473ac341f075abcf3b65ac2723da9ed541cda15`. Eight checks, all pass. Full suite on tree `1bcdad4a6603f16cd582863dd8ed8360255282ef`: 935 runs, 6885 assertions, 0 failures, 0 errors, 0 skips, with provider keys and `SOFT_FOUNDRY_PHASE` unset. CHECK-002 and CHECK-003 record red commits `83cf46a` and `f5c3032`. VER-001 through VER-004 are the gaps review later confirmed; none failed a check.

## Evaluation
Complete at `0c213b4c26aca56a5a4f686bfc4ebf0018be4297`. Sixteen journeys, none failed. EVAL-001 through EVAL-011, EVAL-013, and EVAL-014 exercise the must criteria that are commands. EVAL-015 is smoke for `soft-foundry check`. EVAL-016 is the accessibility pass over the lines the journeys printed. Advisory findings EVA-001 through EVA-007 are the same gaps review recorded.

## Attack
Complete at `46201881662c294728a2fc94d268b6cfadd4cb59`, a rerun on the same code. Twenty-five cases: fifteen denied, ten violated, none refused by a provider. The violations are ATK-F1 through ATK-F10. Review restated them as REV-001 through REV-007, REV-013, and REV-015. No finding is marked `outside_change`. THREAT-009 and THREAT-010 needed no case; review inspected both mitigations and they match.

## Documentation
The product-documentation and FAQ phases are still pending. They are optional. The user text is the committed `README.md` section "Converging: what a change promises, and how many rounds it gets" and `docs/user/converging-changes.md`. Review read both. They name the cap, tiers, the approval, person checks, the blocked basis, outside-change findings, and the documentation-only reopen. They do not name the check `rules kept` (REV-010). That is the documentation leg of AC-017. The README does say that a record without `rules: 2` keeps its old rules and that the new checks skip with "legacy record".

## Observability
`surfaces.observability` is false. The specification says the record is the surface: the refusal, parked status, advisories, and the docs-only flag. The observability phase is still the unused template, and review did not need it. The operator gap is REV-005: when the count includes a remediation that was never sealed, the refusal says those rounds were sealed.

## Review findings
Complete at `d6ed77b077bbbe8a9963f082cfad89706e920ad3`, sealed in the judged commit. Functional, architecture, security, and operations do not conform, because of the findings below. Accessibility conforms with advisories. Policy conformance is N/A (`surfaces.policy` is false; no published policy). Infrastructure is N/A.

REV-001 has severity blocking and a failure, and it is not marked `outside_change`. It is a real defect: after two sealed remediation rounds, deleting `rules` from `metadata.yml` and committing that deletion lets `phase seal remediate` succeed. `rules kept` fails only on the intake gate. Reopen, the remediation seal, and the review and judgment cap checks read current metadata and skip when the key is gone. Deleting the key before the intake seal leaves the record legacy after a note.

This record is legacy, so the new rule that a blocking finding blocks the judgment does not bind this record. The worktree `metadata.yml` holds Jeff Scholen's decision of 2026-11-14, boundary "changes that intentionally weaken required controls": REV-001, REV-002, and REV-003 are a party with write access editing `rules`, `risk`, or `git.branch`, carried to the guard follow-up; REV-004 and REV-005 are follow-ups for the next change; no remediation round is run. That entry is not in `ea2c20a`. Sealing this phase commits `metadata.yml` with the phase directory, which is what records the decision. This phase did not write it.

The majors and minors are in `residual-risk.md` and `evidence.yml`. None are fixed. Remediation has not run.

## Residual risk
Accepted, and explicit in `residual-risk.md`. The largest is that a committer can turn the new rules off by editing metadata, or can spell a changed path so an in-change finding is carried as a follow-up. The named safe cases still hold while `rules: 2` stays in place.
