# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` for command-line output: the `update` command's lines, the help entry, the README section.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-014 | info | messages | One line per outcome, in words, each naming the next step: the releases page, `--yes`, `init`. No colour, no prompt. | CLI rules |
| REV-015 | info | help | Three lines, wrapped like the rest. | CLI rules |

## Conformance
Conforms to the command-line rules. WCAG user-interface criteria do not apply: nothing rendered.
