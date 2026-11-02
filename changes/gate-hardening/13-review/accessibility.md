# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true`. All output is terminal text: the `phase seal` lines, new gate check lines, the `gate` exit code 3, `change summary`, `change new` refusals, and the commit-lineage failure text. Read the code paths that print them and 07-evaluation EVAL-018 (piped output, `NO_COLOR=1`, no ANSI, outcome words beside glyphs, 12-character SHAs, `--json` full values).

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-008 | minor | lock and safe-write refusals, `change summary` on unparseable metadata (ATK-009) | Some refusals print absolute paths, and `change summary` prints `(<unknown>)` for an unparseable metadata.yml. | A reader of a CI log sees `/Users/<name>/...` paths that differ per machine and cannot be searched for by a stable prefix; the `(<unknown>)` line names no file to fix. | CLI rules: stable prefix, repository-relative paths; REQ-032 |
| REV-009 | minor | lineage failure lines in `gate.rb` 455-500 | Failure lines run past 300 characters on one line. They keep one fact and a next action but are long. | A narrow terminal wraps the line; the meaning survives because no layout depends on width. | CLI rules: line-oriented; REQ-032 |

## Conformance
Conforms with advisories. Outcomes are carried by words, no colour or ANSI is emitted, there is no prompt, and refusals name the file, the value and the next action. REV-008 and REV-009 are go-live advisories only.
