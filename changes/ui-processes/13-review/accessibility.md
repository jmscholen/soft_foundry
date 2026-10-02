# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true`. The Running view, the new flags and notes, and the `ps` command's output.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-016 | info | Running table | Caption, scoped headers, a focusable scroll region; no sideways page scroll at 614 px. | 1.3.1, 1.4.10 |
| REV-017 | info | flags and notes | "Running: ...", "Interrupted run", "running now" are words; the molten edge and the tone are additions. | 1.4.1 |
| REV-018 | minor | this page's row | Distinguished by "(this page)" in words and by dimmer text; the dimmer text is the steel colour, 7.1:1 on the surface in the dark scheme and 6.0:1 in the light. | 1.4.3 |
| REV-019 | info | `ps` output | One process per line, a `running:` prefix, `! warn` with the word, no colour, no prompt. Lines are long (about 150 characters with a path). | CLI rules |
| REV-020 | major (evidence gap) | evaluation | No screen reader, light scheme, or zoom, as before. | Evidence the lifecycle expects |

## Conformance
Conforms with advisories.
