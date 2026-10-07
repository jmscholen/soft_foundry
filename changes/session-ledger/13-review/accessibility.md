# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. Examined:

- CLI: `sessions`, `resume`, `hooks install|uninstall --sessions`, the doctor session line, and `phase run`'s new guard warning. No ANSI color is emitted by these paths. Status words used: `resumable`, `folder missing`, `transcript missing`, `installed`, `removed`, `skip`, `none found`, `pass`, `warn`.
- UI: `recordedSection` in `lib/soft_foundry/ui/assets/app.js`, the `el` helper, and `.plain li` / `:focus-visible` in `app.css`. The evaluation screenshot of the change page (`07-evaluation/evidence/recorded-sessions-section.jpg`) shows the heading, the list, text status, and the resume command on its own line. This review did not drive a browser at 320 CSS pixels or with a screen reader; the DOM and CSS were read, and EVAL-005 recorded an accessibility-tree pass.
- Documents: README "Finding and resuming sessions" and the help text. Heading and paragraphs, no image without a text equivalent.

## Findings

| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-A11Y-001 | minor | `SessionLedger#excerpt` | A prompt longer than 140 characters is marked truncated with U+2026 (`…`), and the test requires that character. The command-line rule says meaning must survive stripping every non-ASCII character. After that strip, a cut prompt looks complete. EVAL-007 deleted non-ASCII bytes from `sessions` output; the prompts in that run were short, so the truncation marker was not what was checked. An ASCII `...` would keep the signal and still satisfy AC-004's "ellipsis". | `.ai/rules/accessibility.md`, command-line rule: meaning survives stripping every escape sequence and every non-ASCII character. |
| REV-A11Y-002 | minor | `CLI#resume` | The success path prints only the shell command and exits 0. It does not say `resumable`, `folder missing`, or `transcript missing`. `resume` of a session whose folder is gone still prints a command that cannot `cd` there. `sessions` does print the status word on the `session:` line. The failure path states the outcome in words (`no recorded session`) and names the next command; that part meets the rule. | REQ-SL-013. `.ai/rules/accessibility.md`, command-line rule: every outcome is a word, and an error names what went wrong and what to do next. |

## What conforms

**Command line, other than the two findings.** `sessions` is line-oriented with stable prefixes (`sessions:`, `session:`, `where:`, `first:`, `latest:`, `resume:`). The status is a word on the `session:` line. Install and uninstall lines lead with `installed`, `skip`, or `removed`. Doctor leads with `pass` or `warn` and does not use color. Nothing in these commands prompts. EVAL-007: zero escape sequences, and the stripped output still had the prefixes, the agent, and `resumable`.

**UI, WCAG 2.2 AA as applied by the standard and by the specification.**

- 1.3.1 Info and Relationships. The section is a `section` labelled by an `h2` ("Recorded sessions") and a `ul` of `li`. Open shells stay in their own notes. The agent, phase, time, status, and command are text.
- 1.4.1 Use of Color. Agent and status are words. `.area` is also colored; the word does not depend on it.
- 1.4.10 Reflow. `.plain li` sets `overflow-wrap: anywhere` and `max-width: 80ch`. The screenshot shows long `cd &&` commands wrapping onto the next line. No new horizontal-only control. Not rechecked at 320 CSS pixels in this review.
- 2.1.1 Keyboard. The phase is an `a`. The resume command is selectable text, not a pointer-only button. The page starts nothing.
- 2.4.7 Focus Visible. `:focus-visible` draws a 3px outline. The new section adds no rule that removes it.
- 4.1.2 Name, Role, Value. The link's name is the phase word. The list item's children are in the tree. EVAL-OBS-003 says the list item's computed name is only the direct text (", last prompt , resumable.") because the agent, time, prompt, and command are child elements. That is the children being exposed, not content dropped. The evaluation also says the full text is read in order. A screen reader walking the item gets the agent, the link, the time, the status word, the prompt, and the command. This is not a 4.1.2 failure. No screen reader was run in this review.

**Documents.** The README section is a heading and paragraphs. The table of commands is a fenced sample, not a data table missing headers.

## Conformance

Conforms with advisories. REV-A11Y-001 and REV-A11Y-002 are go-live advisories under `.ai/rules/accessibility.md`. They are not a reason to withhold this handoff.
