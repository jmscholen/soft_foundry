# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces two things a person perceives: command-line output (`doctor`, `check`, `gate`, `change status`, `ci`, `change close`, and the new `advisory:` block) and documents (`.ai/rules/accessibility.md`, the README section, template and schema text). Reviewed against the command-line and document rules of the standard, reading every changed `@out.puts` in `cli.rb`, the rule file, and the evaluation transcript's EVAL-006.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-009 | info | `lib/soft_foundry/cli.rb` `doctor`, `check`, `print_result`, `ci` | Every outcome now carries a word beside its glyph (`✓ pass`, `✗ fail`, `! warn`, `- skip`, `✗ error`, `! warning`). Confirmed in EVAL-006 with every non-ASCII byte stripped: meaning survives. Closes REV-007 from `changes/init-command/13-review/accessibility.md`. | CLI rule 1 (a word for every outcome) |
| REV-010 | info | all CLI output | No ANSI escape sequences emitted anywhere (EVAL-006: zero ESC bytes across five commands); `NO_COLOR` is honored trivially. | CLI rule 2 |
| REV-011 | info | `advisory:` block | One heading line, then one line per notice with a fixed `! warn <area>:` prefix; searchable in a CI log (EVAL-005 found it with `grep`). Each message names the file or phase and what to change. | CLI rules 3 and 5 |
| REV-012 | minor | `lib/soft_foundry/cli.rb` `ci` (pre-existing line), `maturity_report.rb` | The `—` and `…` characters remain in the "merged but not closed" message and the maturity summary. Decorative punctuation; stripping them loses no meaning, so not a violation, but a future consistency pass could replace them with ASCII. | CLI rule 2 (meaning must survive stripping) |
| REV-013 | info | `.ai/rules/accessibility.md`, README section | Real heading hierarchy, bulleted rules, no images, link text is the WCAG URL itself. The README example block is a fenced code block, readable by screen readers as text. | Document rules |
| REV-014 | info | non-interactivity | No prompts were added; `change close` still prints and then closes without input. | CLI rule 4 |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable to this change because it renders no HTML, native, or document UI; what it renders is terminal text and Markdown, which are covered by the CLI and document rules above and were examined directly.
