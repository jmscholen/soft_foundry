# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. A person reads `phase run` and the gate. There is no web or native UI in this diff. Examined:

- The new lines in `CLI#phase`: `shell: <shell> (<who> ran on <provider>; the <skill> skill prefers a different provider)` on standard output, and `! warn shell: ...` on standard error (`choice.line` is printed to `@err` only when it starts with `!`).
- The gate detail for `findings explained` (`no failure: on ...`, or the pass sentence). `print_result` already prefixes gate lines with a status word; this change only changes the detail.
- README paragraphs "A different provider for review and judgment" and "Findings name the failure they prevent": headings, a fenced command block, and prose. No images.
- The "Accessibility observations" section of `07-evaluation/results.md`: the new lines were checked there with non-ASCII bytes deleted. This review re-read the string literals. They are ASCII. No ANSI color is added. Nothing prompts.

No screen reader was run. The change does not add a control, a focus order, a contrast pair, or a layout.

## Findings

None.

## What was compared to the standard

Command-line rules in `.ai/rules/accessibility.md`:

- The success line carries the searchable prefix `shell:`, the same shape as the existing `billing:` prefix. The warning line carries the word `warn`. Neither line uses a glyph or a color as the only signal.
- One fact per line. The sentence still reads if the terminal wraps it; nothing is aligned to a column.
- The warning names what happened and what to do next (`name one with --shell`).
- The tool does not prompt. `--shell` remains a flag.

The `shell:` line does not use one of the example outcome words (`pass`, `fail`, `skip`). The rule's next bullet allows a stable prefix, and this prefix is one. That is not a finding.

REV-FUN-001 is a wrong shell, not an inaccessible line. The warning in that case still uses `warn` and names `--shell`. What it fails to say (that the chosen shell matches a provider it already knows) is the functional finding.

## Conformance

Conforms. The change declares an accessibility surface. The new command lines and the README paragraphs were examined against the command-line and document rules in `.ai/rules/accessibility.md`. Nothing added depends on a glyph, a color, or a fixed width. No finding.
