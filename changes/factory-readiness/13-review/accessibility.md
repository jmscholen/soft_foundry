# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules).

## Scope reviewed
`surfaces.accessibility: true`. The perceivable results are command-line output (`eval`, `guard`, `gate`, `change close`, `doctor`, the tamper line and refusal messages), the README and `.ai/` prose, and the evidence documents. No UI was added. I read the evaluation's accessibility observations and the refusal and outcome strings in `cli.rb`, `guard.rb`, `harness_eval.rb`; I did not run a screen reader.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-009 | minor | `eval` and guard refusal output | Outcome words (pass, fail, skip, error, warn) lead each line after the status glyph, so meaning survives glyph and colour removal; the JSON form carries the same facts. No finding against 1.4.1 or 3.3.1. The only gap is that the next step for a default `eval --live` failure is not in the output or README (REV-007), which weakens error suggestion. | A reader using a screen reader hears "0 findings recorded" with no hint that the permission mode is the cause. | WCAG 2.2 SC 3.3.3 (Error Suggestion), accessibility.md CLI output rule |

Keyboard-only: no command prompts and nothing needs a pointer (SC 2.1.1). Documents use headings and tables with header rows (SC 1.3.1). Errors name the next step in the guard (the `--shell` flag, `--force`, the tamper log).

## Conformance
Conforms with advisories (go-live advisory: REV-009).
