# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true`. The links and the popup.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-012 | info | popup | Dismissable (Escape, blur), hoverable (stays while the pointer is over it), persistent (until dismissed): the three conditions for content on hover or focus. | 1.4.13 |
| REV-013 | info | popup | `role="tooltip"`, referenced by `aria-describedby` from the focused element; a commit reference is focusable. | 4.1.2, 2.1.1 |
| REV-014 | minor | popup content | The description is set when shown; a screen reader reads it after the link's name. Whether that is heard as intended was not tested. | 4.1.2 |
| REV-015 | minor | board headers | 32 links added before the rows; a skip or a way to jump past the header is a possible follow-up. | 2.4.1 |
| REV-016 | minor | the popup's colours | Ink on ground in the light scheme (13.8:1) and surface on ground with a border in the dark (as the page). The path line is at 85% opacity: about 11.7:1 light, 7.1:1 dark on the page's measured palette. | 1.4.3 |
| REV-017 | major (evidence gap) | evaluation | No screen reader, light scheme, or zoom. | Evidence the lifecycle expects |

## Conformance
Conforms with advisories.
