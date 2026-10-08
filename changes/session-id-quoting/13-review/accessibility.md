# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. A person reads `sessions`, `resume`, and the recorded-sessions block on the change page, and pastes the command. Examined:

- `CLI#sessions` and `CLI#resume` at `lib/soft_foundry/cli.rb`. Prefixes `sessions:`, `session:`, `where:`, `first:`, `latest:`, and `resume:` are unchanged. Status words on the `session:` line are unchanged (`resumable`, `folder missing`, `transcript missing`). `resume` with no trusted match prints `resume: no recorded session for change <slug>` and names `soft-foundry sessions --change <slug>`. No ANSI color is emitted on these paths. Nothing prompts.
- `recordedSection` in `lib/soft_foundry/ui/assets/app.js`. This change does not edit that file. The resume string is still a text node (`el` sets `textContent`). The section is still a heading and a list. The page still does not launch the command.
- EVAL-001's transcript: a real Grok id is printed on one `resume:` line, with the word `resumable` on the `session:` line, and the command matches the unquoted alphabet (no new escapes for a normal id).
- Documents: this change does not edit README or help text. The user-documentation phase has not run.

No screen reader was run, and the page was not resized to 320 CSS pixels. The change does not alter layout, contrast, focus, or names of controls.

## Findings

None.

## What was compared to the standard

Command-line rules in `.ai/rules/accessibility.md`: an outcome is a word, not a glyph or a color; output is one fact per line with a stable prefix; meaning does not depend on terminal width; the tool does not prompt; a refusal names what happened and what to do next. `sessions` and the `resume` refusal meet those rules, and they met them before this change. Filtering a line adds no glyph. For an id in the alphabet `Shellwords` leaves alone, the printed command is the same bytes as 0.18.0.

The recorded-sessions block was checked against WCAG 2.2 success criteria 1.3.1 (Info and Relationships) and 4.1.2 (Name, Role, Value). The heading, list, and text node are unchanged. The command is text, so a quoted id would be read as characters, not dropped. This change does not add a control.

Parent findings about the ellipsis character and about `resume` printing a command with no status word are unchanged and are outside this change's non-goals. They are not re-filed.

Skipping a bad line without a warning is the intake decision. The empty result still uses the words `none found` and `recorded`. That is not a glyph-only outcome.

## Conformance

Conforms. The change declares an accessibility surface. Command output and the recorded-sessions text were examined against the command-line rules and against WCAG 2.2 criteria 1.3.1 and 4.1.2. Nothing added by this change depends on a glyph, a color, or a fixed width. No finding.
