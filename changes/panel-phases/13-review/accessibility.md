# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. A person invokes `soft-foundry phase run --panel` and reads its stdout and stderr. No HTML or native UI is added. Examined `CLI#panel_run`, `Panel#run` status lines, the help text, the README panel section, the live transcript in `07-evaluation/evidence/live-panel-transcript.log`, and the lines produced by the stand-in panels in this review. The specification phase was skipped, so there is no requirement with `category: accessibility`. That gap is the go-live advisory the record already produces, not a separate finding.

## Findings

None. REV-A11Y-001 (refusals and failures did not start with a fail word) and REV-A11Y-002 (the agreed and no-agreement lines had no pass or warn word) are closed. Reproduced here: agreement prints `✓ pass panel: agreed after 1 round: ...`, no agreement prints `! warn panel: no agreement after ...`, a dropped member and a split print `! warn panel:`, and refusals and integrity failures print `✗ fail panel:`. Stripping the glyph leaves `pass`, `warn`, or `fail`.

The two introductory lines use the stable prefix `panel:` (members, round limit, session ceiling). The `running ... as a panel` line matches the single-session runner. Those are facts, not outcomes. `.ai/rules/accessibility.md` allows a stable searchable prefix for a fact and requires a status word for an outcome.

## Conformance

Conforms. No ANSI color is emitted by the runner. Output is one fact per line. The command does not prompt. Error lines name the phase and the reason. A not-applicable statement would be wrong: a person operates the command and reads its output.
