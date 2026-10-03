# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared, so this review is not N/A. The change produces command-line output (two help entries, JSON on stdout, one error line) and a README paragraph. It renders no HTML.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-013 | info | JSON output | No colour, no symbols; every outcome is a word (`pass`, `fail`, `stale`). | CLI rules: no colour unless a TTY; outcome as a word |
| REV-014 | info | help text | Both entries read complete with non-ASCII bytes stripped (EVAL-005). The `change status` entry runs to four lines, in the same wrapped style as its neighbours. | CLI rule on line length and wrapping |
| REV-015 | info | `--json` | A flag, not a prompt. | "Commands do not prompt interactively; every decision is a flag" |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable because the change renders no HTML, native, or document UI; they apply in full to the next change.
