# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces command-line output (the Codex install lines, the combined doctor line, the per-shell runner warnings, patch refusals naming several paths) and documents (README guard and runner sections, `AGENTS.md`).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-012 | info | all new output | Every line carries its outcome as a word and survives stripping non-ASCII bytes (EVAL-005); a refusal names each offending path in one line. | CLI rules 1, 3, 5 |
| REV-013 | minor | `doctor` guard line | About 130 characters, both hosts and the mode on one line. Same follow-up family as the earlier long-line findings. | CLI rule 5 |
| REV-014 | info | README | The Codex paragraph states the trust step in plain words before the mechanism; the runner block gains one commented line for Grok. | Document rules |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable because the change renders no HTML, native, or document UI.
