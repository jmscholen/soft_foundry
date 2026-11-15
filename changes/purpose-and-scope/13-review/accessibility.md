# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility` is true: the result is Markdown a person reads. Examined at commit 5844763: the 38 lines added by d944d07 and the heading outline of the four files they sit in (`README.md`, `.ai/README.md`, `.ai/skills/adversarial-testing/SKILL.md`, `.ai/skills/review/SKILL.md`). No user interface, command-line output, error message or notification changed, so the user interface rules and the command-line rules have nothing to apply to.

Against "Document and report rules" and the success criteria they apply:

- **Heading hierarchy (document rule 1; WCAG 1.3.1 Info and Relationships, 2.4.6 Headings and Labels).** Each file has one level-1 heading. The three new headings (`Purpose` twice, `The attacker`) and the one added over existing text (`Skills and modes`) are level 2 directly under the title. No level is skipped anywhere in the four files. Each heading names what its section holds.
- **Lists and tables (document rule 1; WCAG 1.3.1).** The three ideas of Purpose are a bulleted list and the nine attack classes are an ordered list, both real Markdown lists. No table was added.
- **No meaning by colour or symbol alone (WCAG 1.4.1 Use of Color; command-line rule 1 by analogy).** No colour is named and no glyph is used. Every added byte is ASCII (byte scan by this session). The bold lead-ins of Purpose are complete sentences that read the same with the emphasis removed. "Out of scope" is said in words. The list numbers carry order only; the text does not refer to a class by its number.
- **Link text (document rule 1; WCAG 2.4.4 Link Purpose).** No link was added. File paths are inline code and are named in the sentence around them.
- **Images (document rule 2; WCAG 1.1.1 Non-text Content).** None added.
- **Hidden characters (REQ-005).** None: no control character in any of the four files at HEAD, and `soft-foundry check` passes its content scan.

This is the reading judgment VER-003 left to this review: no meaning in the added text rests on a symbol, a colour or layout.

Not examined: how a hosted renderer displays the Markdown (contrast, zoom, reflow). That belongs to the viewer.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| none | n/a | n/a | No accessibility finding. | n/a | Document and report rules; WCAG 1.3.1, 1.4.1, 2.4.4, 2.4.6 examined |

## Conformance
Conforms. The added text meets the document rules of `.ai/rules/accessibility.md` and REQ-005 / AC-005. No go-live advisory is raised.
