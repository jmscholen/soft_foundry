# Accessibility Review

Standard: `.ai/rules/accessibility.md` (command-line and log output rules; document rules for the README). `surfaces.accessibility` is true. No web or native UI is in this change, so WCAG 2.2 AA's widget criteria are not the surface. The CLI rules are.

## Scope reviewed

Every line `panel_run` and `Panel#run` print: refusals (`✗ fail panel:`), the member and session-count lines (`panel:`), dry-run `would run` lines, `running ... as a panel`, `✓ pass panel: agreed`, `! warn panel: no agreement`, the spoil warning, the dropped-member warning, the split parking warning, and each `✗ fail panel:` failure. Also the generic `CLI#run` rescue, which is where a deleted `ARGUMENT.md` lands, and the panel section of `README.md` (headings, no images, link text is the command itself). No ANSI color is emitted on these paths. Glyphs are accompanied by `pass`, `fail`, or `warn` except on the rescue path below. The specification phase was skipped for this change, so there is no `category: accessibility` requirement; that gap is the go-live advisory the gate already prints, not a new finding.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-FUN-008 | minor | `Panel#run` argument loop; `CLI#run` rescue of `StandardError` | The reachable failure "member deletes `ARGUMENT.md`" is not a `fail` line. | Argument stage, first of two members, deletes `panel/ARGUMENT.md` (the argument stage may write that path). The next turn raises `Errno::ENOENT`. The person sees `soft-foundry: No such file or directory @ rb_sysopen - .../ARGUMENT.md` and exit 1. There is no `fail` / `warn` word, the handoff stays `pending`, and the line does not say what to do next. A screen reader or a log search for `fail panel` does not find it. | `.ai/rules/accessibility.md`, command-line rules: every outcome carries a word (`pass`, `fail`, `warn`, `skip`, `created`, `conflict`); an error names what went wrong and what to do next. |

The informational `panel:` and `running` lines are not outcomes. They use a stable searchable prefix. Outcome lines for agree, split, refuse, and snapshot failure use `pass`, `warn`, or `fail` plus the glyph. Those match the rule.

## Conformance

Conforms with advisories. REV-FUN-008 is the advisory. It is not a reason to withhold this handoff.
