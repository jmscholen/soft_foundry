# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true`. The Repositories page, the repository bar, the changed navigation, the token page, and the changed terminal line.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-019 | info | wayfinding | Every page's title names the repository; the bar is a labelled nav landmark with the current tab marked; there is one way in and one way back. This is the change's purpose and it holds in the DOM. | 2.4.2, 2.4.8, 1.3.1 |
| REV-020 | info | cards | h2 for the repository, h3 for Sessions, Commands running, Open changes; lists inside; all state in words. | 1.3.1, 2.4.6, 1.4.1 |
| REV-021 | info | token page | A heading and a paragraph saying what is missing and what to do. | 3.3.1, 3.3.3 |
| REV-022 | minor | two navigation landmarks | "Views" in the header and "Repository" in the page. Both are labelled; a screen-reader pass should confirm the order makes sense. | 1.3.1 |
| REV-023 | minor | card top edge | A molten edge marks a card with something running; the same fact is in the Sessions list in words. | 1.4.1 |
| REV-024 | minor | the printed link | About 80 characters with a random code. It is one line with the `ui:` prefix. A person using a screen reader must copy it rather than read it. | CLI rules |
| REV-025 | major (evidence gap) | evaluation | No screen reader, light scheme, or zoom, as before. | Evidence the lifecycle expects |

## Conformance
Conforms with advisories.
