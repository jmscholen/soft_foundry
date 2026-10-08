# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. There is no web or native UI in this change. The surface is the new CLI output of `phase run --panel`: the `panel:` lines, `running`, dry-run `would run` lines, `! warn panel:` lines, refusals (`cannot run ... as a panel`), and the help text. Compared with the command-line rules in `.ai/rules/accessibility.md` and with the lines captured in `07-evaluation/evidence/live-panel-transcript.log`. No ANSI sequences were added. The command takes every choice as a flag.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-A11Y-001 | minor | `CLI#panel_run` refusal lines | A refused panel prints `slug: cannot run <phase> as a panel: <reason>` on stderr with no status word and no `panel:` prefix. The success and split lines use `panel:` and `! warn panel:`. A log search for `fail` or `panel:` misses the refusal. The reason itself names what was wrong and which phases or values are allowed. | `phase run implement --panel claude,grok` prints `panel-phases: cannot run implement as a panel: implement is not a panel phase (...)`. A reader or a log search that keys on `fail`, `warn`, or `panel:` does not see the refusal. The exit code is still non-zero. | `.ai/rules/accessibility.md`, command-line rules: every outcome is a word (`pass`, `fail`, `warn`, `skip`, `created`, `conflict`), not a glyph or color alone; line-oriented output with a stable searchable prefix |

## What holds

`panel: agreed ...` and `panel: no agreement ...` carry the outcome in words. `! warn panel:` carries `warn`. Dry-run lines start with `would run`. None of these depend on color or a glyph. `NO_COLOR` does not arise: the new lines emit no ANSI. Output is one fact per line. The long agree sentence printed on the `panel: agreed` line is the members' text, not a layout that has to fit a terminal width; the status word is still on that line. Evaluation's accessibility note matches this.

No WCAG 2.2 UI criterion applies: the change adds no page, control, or document layout. The user-facing documents for the feature are `README.md` and the help text, which use headings and a command block, not a diagram.

## Conformance

Conforms with advisories. REV-A11Y-001 is the advisory. A person operates the new command and reads its output, so a not-applicable statement would be wrong here.

The specification phase was skipped, so there is no `category: accessibility` requirement for this review to check against. Intake states the command's output rules only as "every new output line carries a status word." That gap is a go-live advisory of its own; it is not a finding against the code.
