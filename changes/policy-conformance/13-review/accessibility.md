# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces two things a person perceives: command-line output (the new `! warn policy:` advisory lines, the `! warning` from `check`, and the `[status: awaiting_human]` header) and documents (`.ai/rules/policy-conformance.md`, the review template, the README section, template and schema text). Reviewed against the command-line and document rules of the standard, reading every new message in `advisory.rb` and `check.rb`, the rule file, and the evaluation transcript's EVAL-008.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-012 | info | `lib/soft_foundry/advisory.rb` policy notices | Every policy advisory is one line, starts with the word `warn` beside its glyph and the area `policy:`, names the file and the action, and survives stripping every non-ASCII byte (EVAL-008). | CLI rules 1, 3, 5 |
| REV-013 | info | `lib/soft_foundry/check.rb` `check_policy_standard` | The new warning carries the word `warning`, names the missing file, and says "(advisory only)" so the reader knows the exit code is unaffected (EVAL-007). | CLI rules 1 and 5 |
| REV-014 | info | all CLI output | No escape sequences (EVAL-008: zero ESC bytes); no prompts were added, and `change status` remains non-interactive with the parked state in its first line. | CLI rules 2 and 4 |
| REV-015 | info | `.ai/rules/policy-conformance.md`, review template, README section | Real heading hierarchy, bulleted rules, one table with a header row in the template, the README example inside a fenced code block, no images. | Document rules |
| REV-016 | minor | `lib/soft_foundry/advisory.rb` `policy_notices` (undeclared surface) | The longest message runs to about 250 characters on one line. Line-oriented as the standard asks, but a screen reader reads it as one sentence; splitting the "confirm or set the flag" instruction onto a second indented line would help. Not a violation. | CLI rule 3 |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable to this change because it renders no HTML, native, or document UI; what it renders is terminal text and Markdown, which are covered by the CLI and document rules above and were examined directly.
