# Functional Review

## Scope reviewed
Every requirement in `00-intake/request.md` (REQ-A11Y-001 to REQ-A11Y-007) against commit `2c74a369`: `lib/soft_foundry/advisory.rb`, the `cli.rb` output paths (`doctor`, `check`, `print_result`, `ci`, `status`, `gate`, `change_close`), `change_record.rb`'s flag edit, `maturity_scan.rb`, `check.rb`, the control-plane edits, and the evaluation transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | minor | `README.md` (Maturity assessment section, pre-existing) | Documents `--maturity=scan` / `--maturity=deep`, but `CLI#option` only accepts the value as a separate argument, so the documented spelling fails with "unknown option(s)". Surfaced by EVAL-007. Outside this change's scope; fix the README or teach `option` the `=` form in a follow-up. | `.ai/rules/accessibility.md` (error messages name what to do next; here the documentation sends the user to a wrong spelling) |
| REV-002 | info | `lib/soft_foundry/advisory.rb` `evaluation_notices` | A results file whose "Accessibility observations" section contains the letters N/A anywhere (for example "keyboard: exercised; contrast: N/A, terminal output") is advised as missing observations. Conservative in the right direction for an advisory, and the message says what to change. | REQ-A11Y-003 |
| REV-003 | info | `lib/soft_foundry/cli.rb` `ci` | Advisories print only for open records; the eight closed historical records that skipped review are not re-advised on every `ci` run. Deliberate (decisions.md) and consistent with `ci` already skipping closed records. | REQ-A11Y-005 |

## Conformance
Conforms. Every requirement is implemented and exercised: REQ-A11Y-001 by EVAL-006 and `StatusWordTest`; REQ-A11Y-002 by the rule file and EVAL-007; REQ-A11Y-003 by EVAL-001 to EVAL-004 and `AdvisoryTest`; REQ-A11Y-004 and REQ-A11Y-005 by EVAL-005 (exit code 0 on gate, status, ci, and close) and `AdvisoryCLITest`; REQ-A11Y-006 by `MaturityScoringTest`/`MaturityScanTest` and EVAL-007; REQ-A11Y-007 by EVAL-007 and `StatusWordTest#test_check_summary_and_findings_carry_words`.
