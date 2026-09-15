# Functional Review

## Scope reviewed
Every requirement in `00-intake/request.md` (REQ-POL-001 to REQ-POL-008) against commit `05f44e9a`: `.ai/rules/policy-conformance.md`, the review, specification, discovery, and threat-modeling skill edits, the templates, `lib/soft_foundry/advisory.rb`, `change_record.rb`'s surface edits, `maturity_scan.rb`'s document detection and capability, `check.rb`, the control-plane and policy edits, the tests, and the evaluation transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | minor | `lib/soft_foundry/advisory.rb` `policy_notices` (and the accessibility equivalent it mirrors) | A change in a repository with published policies that legitimately alters nothing the policies cover is advised to "confirm" on every gate run, and there is no place to record that confirmation, so the notice never clears. Same trait as the accessibility false-flag notice. A `surfaces_rationale` (or similar) in `metadata.yml` that silences the notice with a reason is the obvious follow-up. | REQ-POL-003 |
| REV-002 | info | `lib/soft_foundry/advisory.rb` `policy_text_change_notices` | The "Policy text changes required" section counts as owed unless empty or starting with the word "None". A reviewer who writes "No changes." is advised as owing a change. Conservative in the right direction for an advisory, and the template says to write None. | REQ-POL-005 |
| REV-003 | info | `lib/soft_foundry/maturity_scan.rb` `policies` | The scan never writes MISSING (EVAL-001 and EVAL-007 confirm UNKNOWN with a rationale naming every directory it looked in). Only discovery may establish absence, as the standard requires. | REQ-POL-002 |
| REV-004 | info | `lib/soft_foundry/cli.rb` `ci` | Advisories still print only for open records; the ten closed historical records are not re-advised for a missing policy review. Consistent with the accessibility change's decision. | REQ-POL-006 |

## Conformance
Conforms. Every requirement is implemented and exercised: REQ-POL-001 by the rule file, the skill edits, and EVAL-007; REQ-POL-002 by `MaturityScanTest` and EVAL-001/006; REQ-POL-003 by `PolicyAdvisoryTest` and EVAL-001/002/005/006; REQ-POL-004 by `check` (a required file with a template) and EVAL-003; REQ-POL-005 by `test_policy_text_changes_owed_are_a_legal_commitment_until_a_person_decides` and EVAL-004; REQ-POL-006 by every journey's exit code and `test_gate_prints_policy_advisories_and_still_exits_zero`; REQ-POL-007 by `MaturityScoringTest`, `MaturityScanTest`, and EVAL-007; REQ-POL-008 by `StatusWordTest#test_check_summary_and_findings_carry_words` and EVAL-007.
