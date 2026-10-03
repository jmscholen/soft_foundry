# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true`. The page (both views, the gate panel, messages), the `ui` command's output, and the README section. Evidence: `07-evaluation/evidence/browser-observations.log`, `test/ui_assets_test.rb`, and the stylesheet.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-019 | info | marks and cells | Every state is a distinct shape plus a word; board cells carry the word for assistive technology and a key is shown. | 1.4.1 Use of Color |
| REV-020 | info | palette | Text is at least 5.1:1 in the light scheme and 7.2:1 in the dark. The pale divider colour is used only for rules and for the unstarted part of the gate line, where the word "Pending" carries the meaning. | 1.4.3, 1.4.11 |
| REV-021 | info | controls | Links and buttons only; a real Tab press shows a 3 px outline; focus survives a live update and a gate selection. | 2.1.1, 2.4.3, 2.4.7 |
| REV-022 | info | structure | `lang`, a title per view, one h1, section headings, landmarks, table caption and scoped headers, a skip link. Focus moves to the heading on navigation. | 3.1.1, 2.4.2, 1.3.1, 2.4.1 |
| REV-023 | minor | gate strip | Sixteen buttons each with `aria-expanded` share one panel. It works as a disclosure, but it behaves like a tab list, and arrow-key movement is not offered. A screen-reader pass should decide which pattern to keep. | 4.1.2 Name, Role, Value |
| REV-024 | minor | in-progress gate | Its top edge pulses indefinitely. It stops under reduced-motion but not with the Pause control. | 2.2.2 Pause, Stop, Hide |
| REV-025 | minor | live region | A changed view is announced as "This change was updated at ..."; it does not say what changed. | 4.1.3 Status Messages |
| REV-026 | major (evidence gap) | evaluation | No screen reader was run, the light scheme was not viewed, and 200% zoom and a real 320 px viewport were not exercised. | Evidence the lifecycle expects |
| REV-027 | info | `ui` output | Two lines, each starting `ui:`, outcome in words, no colour, no prompt. | CLI rules |

## Conformance
Conforms with advisories. REV-026 is owed by a person before the page is called conformant; REV-023 to REV-025 are follow-ups.
