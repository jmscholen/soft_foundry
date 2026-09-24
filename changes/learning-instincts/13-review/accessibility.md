# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces command-line output (the `instincts valid` gate line, `learn list` lines, `learn promote` lines and refusals) and documents (the instincts template, the learning skill text, the policy comment, `learned.md`, the README section).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-013 | info | `lib/soft_foundry/cli.rb` `learn`, `gate.rb` | Every line carries its outcome as a word (`✓ pass promoted`, `- skip`, `✗ fail`, `would promote`) or starts with the confidence, and survives stripping non-ASCII bytes (EVAL-006). | CLI rules 1, 3, 5 |
| REV-014 | minor | `learn list` | A line carries the whole trigger and action and can exceed 200 characters (EVAL-NOTE-001). Follow-up: a `--short` form printing confidence, change, and id only. | CLI rule 5 |
| REV-015 | info | `.ai/rules/learned.md` sections | Real headings per instinct with bold labels for When, Do, and Confidence; a screen reader navigates by heading. | Document rules |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable because the change renders no HTML, native, or document UI.
