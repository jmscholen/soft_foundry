# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. A person invokes `soft-foundry phase run --panel` and reads its stdout and stderr. No HTML or native UI is added. Examined `CLI#panel_run`, `Panel#run` status lines, the help text, the README panel section, and the live transcript in `07-evaluation/evidence/live-panel-transcript.log`. The specification phase was skipped, so there is no requirement with `category: accessibility`; that gap is the go-live advisory the record already produces, not a separate finding.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-A11Y-002 | minor | `CLI#panel_run` agreed and no-agreement lines | Refusals and failures now start with `✗ fail panel:` and the split and continue lines start with `! warn panel:`. The outcome lines do not. They are `panel: agreed after N rounds: ...` and `panel: no agreement after N rounds`. Stripping the glyph leaves those lines without `pass`, `fail`, `warn`, `skip`, `created`, or `conflict`. | `phase run specify --panel claude,grok` when the members agree. The success line is `panel: agreed after 1 round: same`. A log search for `pass` or `fail` does not find it. The command's exit code is 0, which a screen reader on the transcript does not get from that line. | `.ai/rules/accessibility.md`, Command-line and log output rules (every outcome is a word: pass, fail, warn, skip, created, or conflict; a glyph may accompany the word) |

## Conformance

Conforms with advisories. REV-A11Y-002 is the advisory. Refusals, the split park, and the dropped-member warning meet the status-word rule. No ANSI color is emitted. Output is one fact per line with a `panel:` prefix. The command does not prompt. A not-applicable statement would be wrong: a person operates the command and reads its output.
