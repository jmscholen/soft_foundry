# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces two things a person perceives: command-line output (the track line under `change new` and `change status`, the `vet` and `reopen` messages and refusals, the `fail not exploring`, `fail track permitted`, and `pass`/`fail specification locked` gate lines, the `! warn environment:` advisory, `check`'s tracks errors) and documents (`.ai/skills/exploration/SKILL.md`, the `tracks:` comment in `workflow.yml`, the template comments, the README section, `AGENTS.md` step 4, `.ai/schemas.md`).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-016 | info | `lib/soft_foundry/gate.rb`, `cli.rb`, `advisory.rb` | Every new line carries its outcome as a word beside the glyph (`✓ pass`, `✗ fail`, `! warn`) and survives stripping every non-ASCII byte (EVAL-011). `vet` prints one `✗ fail` line per reason so they can be acted on one at a time. | CLI rules 1, 3, 5 |
| REV-017 | info | all CLI output | No escape sequences (EVAL-011: zero ESC bytes); no prompts were added; `vet` and `reopen` are one-shot commands with their result in the first line. | CLI rules 2 and 4 |
| REV-018 | minor | `lib/soft_foundry/cli.rb` `track_line`, `change_vet`; `advisory.rb` `environment_notices` | Three messages run to about 170 characters on one line (EVAL-NOTE-001). Line-oriented as the standard asks, but a screen reader reads each as one long sentence; the parenthetical "run `soft-foundry change vet` when the person has accepted the feature" could move to a second indented line. Follow-up. | CLI rule 5 (plain language) |
| REV-019 | info | `.ai/skills/exploration/SKILL.md`, README section, `AGENTS.md` step 4 | Real heading hierarchy, a fenced code block for the command sequence, no images; the README section states the rule before the mechanism. `AGENTS.md` step 4 is a long paragraph, matching the surrounding steps. | Document rules |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable to this change because it renders no HTML, native, or document UI; what it renders is terminal text and Markdown, which are covered by the CLI and document rules above and were exercised with the glyphs removed in EVAL-011.
