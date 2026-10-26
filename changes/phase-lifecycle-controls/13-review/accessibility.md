# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. Examined the new command output paths in `cli.rb` (reopen, parallel, release, discharge, ci released lines, usage text) and the released UI in `lib/soft_foundry/ui/assets/app.js` (`releaseSection`, board released section, timeline kind labels) and `app.css` (`.release-items`, `.sr-only`, `:focus-visible`). Read evaluation's accessibility observations and `07-evaluation/evidence/j9-a11y-counts.txt` claim as recorded in `07-evaluation/results.md` (0 non-ASCII bytes in the captured reopen, release, discharge, and parallel-refusal lines). Computed contrast for the new table header color. Did not operate the rendered page with a keyboard or a screen reader.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-002 | major | `ui/assets/app.js` `releaseSection` state cell | The released table chooses "open" or "discharged" with JavaScript truthiness of `discharged_at`. An empty string takes the open branch. The CLI uses Ruby truthiness and announces the same item as discharged. The state word in the table is not the state the rest of the product announces. | A record with `discharged_at: ""` shows "open" in the table and "0 open item(s)" on `change status`. A person using the page and a person using the CLI do not share one state for that item. | WCAG 1.3.1 Info and Relationships; REQ-025 |

## What was examined and held

- CLI. New success lines use the words `reopened`, `reset`, `pass`, `fail`, `warn`, `released`, and `discharged`, with the prefixes `phase reopen:`, `phase <id>:`, `parallel:`, `released:`, and `advisory:`. Refusals name what happened and the next command (AC-047, evaluation EVAL-008). No command in this change reads a prompt from stdin. The `ci` released-failure line uses a glyph beside the word `fail`, the same pattern as the existing gate lines. Meaning remains after the glyph is removed (`.ai/rules/accessibility.md` command-line rules).
- UI structure. The released items are a `table` with a `caption` (class `sr-only`), `th scope="col"` headers, and `th scope="row"` ids. The section heading includes the word "Released" and the open-item count. The board uses the same words, not color alone (1.4.1, 1.3.1, 4.1.2). Record text is set through `el(..., { text })`.
- Contrast. `.release-items thead th` is `--steel` on `--surface`. Computed ratio 6.03:1 in the light palette (`#55606c` on `#f7f8fa`) and 7.12:1 in the dark palette (`#a3adb8` on `#1c2127`), both above the 4.5:1 AA threshold for this size and weight (1.4.3).
- Focus. The table sits in a `div.scroller` with `tabindex="0"`, `role="group"`, and `aria-labelledby` pointing at the section heading. `:focus-visible` draws a 3px outline. No new control is mouse-only in the source. Rendered focus order and screen-reader announcement were not exercised.
- Documents. `README.md` uses a heading hierarchy for the new commands and the link text in the surrounding README is descriptive. `docs/user/README.md` does not yet describe the commands (REV-004). That file is a stub, so it does not publish a broken heading structure.

## Conformance

Conforms with advisories. REV-002 is the advisory. CLI output and the released table's structure, state words, and header contrast meet the standard for the source and the captured output that were examined. Keyboard and screen-reader operation of the rendered released view were not run in a browser.
