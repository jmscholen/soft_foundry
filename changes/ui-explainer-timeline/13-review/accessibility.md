# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true`. The Workflow view, the Timeline and Spend sections, and the pause behaviour.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-012 | info | workflow strip | "Required" and "Optional" are words; the dashed edge is an addition, not the only signal. | 1.4.1 |
| REV-013 | info | spend table | Caption, scoped headers, a focusable scroll region; "Over", "Within", "Unknown" in words, with colour only on "Over". | 1.3.1, 1.4.1 |
| REV-014 | info | pause | `data-paused` stops the gate animation, closing ui-server REV-024. | 2.2.2 |
| REV-015 | minor | heading focus | The h1 that receives focus on navigation now shows no outline. It is not interactive and focus is only parked there for screen readers, but a sighted keyboard user sees no indicator until the next Tab. | 2.4.7 |
| REV-016 | major (evidence gap) | evaluation | As in ui-server: no screen reader, light scheme, 200% zoom, or 320 px viewport was exercised for the new views. | Evidence the lifecycle expects |
| REV-017 | minor | gate strip pattern, announcement | ui-server REV-023 and REV-025 remain open. | 4.1.2, 4.1.3 |

## Conformance
Conforms with advisories. REV-016 is owed by a person.
