# Accessibility Standard

Applies to any change that produces something a person perceives or operates: HTML or native UI, documents and reports, command-line output, error messages, and notifications. Implementation loads this file whenever `surfaces.accessibility` is `true` in the change's `metadata.yml`; review cites it in `13-review/accessibility.md`. Findings against this standard are reported as go-live advisories, never as a blocker to lifecycle advancement: `soft-foundry gate`, `change status`, `ci`, and `change close` print what still needs attention before the change goes live, and the human deciding to ship owns that call.

## Conformance target

- Web, native, and document user interfaces conform to **WCAG 2.2 Level AA** (https://www.w3.org/TR/WCAG22/). Cite the success criterion number (for example 1.4.3 Contrast (Minimum), 2.1.1 Keyboard, 4.1.2 Name, Role, Value) in every finding and requirement.
- A repository may name a stricter or more specific standard (Section 508, EN 301 549, a platform HIG) in its own rules; the stricter requirement wins.
- "N/A" is a valid conformance statement only when the change produces nothing a person perceives or operates, and the review must say what was examined to reach that conclusion.

## User interface rules (WCAG 2.2 AA, applied)

- Every interactive control is reachable and operable with the keyboard alone, in a sensible focus order, with a visible focus indicator (2.1.1, 2.4.3, 2.4.7, 2.4.11).
- Every control, image, and icon has an accessible name; state is exposed programmatically, not only visually (1.1.1, 4.1.2).
- Color is never the only carrier of meaning; text and meaningful graphics meet the AA contrast ratios (1.4.1, 1.4.3, 1.4.11).
- Form fields have associated labels; errors are described in text, identify the field, and suggest a correction where possible (1.3.1, 3.3.1, 3.3.2, 3.3.3).
- Content reflows to 320 CSS pixels wide and survives 200% zoom without loss of function (1.4.4, 1.4.10).
- Motion, autoplay, and time limits can be paused, stopped, or extended (2.2.1, 2.2.2, 2.3.1).
- Page and view titles, headings, landmarks, and language are declared so assistive technology can navigate structure (2.4.2, 2.4.6, 1.3.1, 3.1.1).
- Target size for pointer inputs is at least 24 by 24 CSS pixels, and drag operations have a single-pointer alternative (2.5.7, 2.5.8).
- Authentication does not rely on a cognitive function test with no alternative (3.3.8).

## Command-line and log output rules

These apply to every CLI Soft Foundry governs, including `soft-foundry` itself, because agents, CI logs, terminals without Unicode fonts, and screen readers all consume the same bytes.

- Every outcome is conveyed by a word (`pass`, `fail`, `warn`, `skip`, `created`, `conflict`), never by a glyph or color alone. A glyph may accompany the word.
- No ANSI color or styling is emitted unless the output is a TTY and `NO_COLOR` is unset; meaning must survive stripping every escape sequence and every non-ASCII character.
- Output is line-oriented: one fact per line, a stable prefix (`billing:`, `advisory:`, `summary:`) that can be searched for, and no layout that depends on a fixed terminal width to be understood.
- Commands do not prompt interactively; every decision is a flag, so the tool can be driven without a terminal.
- Error messages name what went wrong and what to do next in plain language.

## Document and report rules

- Markdown and HTML reports use a real heading hierarchy, tables only for tabular data with a header row, and link text that describes the destination.
- Images and diagrams carry alternative text that states what the reader needs to know from them.

## Evidence the lifecycle expects

- **Specification** records at least one requirement with `category: accessibility`, or states why the change produces nothing a person perceives.
- **Evaluation** exercises keyboard-only operation, focus and error behavior, and screen-reader readable output where a UI or CLI exists, and records the result under "Accessibility observations".
- **Review** fills `13-review/accessibility.md` with the scope examined, findings citing a success criterion or a rule above, and a conformance statement.
