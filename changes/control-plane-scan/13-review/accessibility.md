# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces command-line output (`check` findings, the `content clean` gate line, `scan` lines and summary) and documents (the README section with its table, the policy comment, the rule line).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-013 | info | all new output | Every line carries its outcome as a word (`✗ error`, `! warning`, `✓ pass scan`, `✗ fail scan`, `✓/!/✗ content clean`) and survives stripping non-ASCII bytes (EVAL-007); an invisible character is named by code point and name so a reader knows what was found without seeing it. | CLI rules 1, 3, 5 |
| REV-014 | minor | override and fetch_exec details | The marker hint repeats on every such finding (EVAL-NOTE-001); on a long scan a screen reader hears it many times. Follow-up: say it once in the summary. | CLI rule 5 |
| REV-015 | info | README section | A four-row table with a header row explains the kinds and levels; the example output is in a code block. | Document rules |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable because the change renders no HTML, native, or document UI.
