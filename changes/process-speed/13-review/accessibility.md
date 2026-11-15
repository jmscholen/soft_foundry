# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility` is true. There is no visual UI. The `ui` snapshot still shows parked status through fields that already existed. The perceivable surface is command-line output and the documents this change adds or edits: refusal and advisory lines in `ProcessRules#cap_refusal`, `PhaseReopen`, `Gate` check details, `Advisory`, `README.md` (the converging section and the accessibility section), and `docs/user/converging-changes.md`.

Evaluation drove the new commands with `NO_COLOR=1` and recorded, in `07-evaluation/results.md` under Accessibility observations, that the outcome words `pass`, `fail`, `warn`, and `skip` survive stripping ANSI and non-ASCII, that the runs did not prompt, and that refusals name the next action. This review measured `cap_refusal(2)` at 506 characters and one line.

REQ-016 is the accessibility requirement. The documents use a heading hierarchy, fenced examples, and no images.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-012 | minor | `lib/soft_foundry/process_rules.rb` `cap_refusal` | The cap refusal is one line of 506 characters. It carries the outcome (the seal or reopen is refused), the parked status, the boundary, and all three decisions in that single line. Outcome words are present, and evaluation saw no color-only meaning. The line is still one fact piled into one line. | `phase seal remediate` or `phase reopen remediate` at two sealed rounds prints that line (EVAL-004, and a measurement of `cap_refusal(2)` on 2026-11-14). A screen reader or a narrow CI log gets one undifferentiated sentence, and a person scanning for the decision words has to read the whole line. | `.ai/rules/accessibility.md`, Command-line and log output rules: one fact per line, a stable prefix, plain language naming what to do next. REQ-016, AC-019 |
| REV-014 | minor | `lib/soft_foundry/phase_reopen.rb` `refuse_status!` | A second reopen, once status is already `awaiting_human`, says only that a person must record the decision under `human_decisions`. It does not repeat the boundary, the round count, or the three decisions. The `change status` advisory still carries the cap text. The first refusal is the long line in REV-012. | Status `awaiting_human`, `phase reopen remediate`: the error has no boundary, no `rounds` value, and no `accept_residual`, `narrow`, or `reject` (EVA-003). A person who still has the first refusal can continue; a person who has only this line is not told which decision to record. | `.ai/rules/accessibility.md`, Command-line rules: error messages name what went wrong and what to do next. REQ-016 |

## Conformance

Conforms with advisories. The new lines use outcome words rather than color or a glyph, commands do not prompt, and the documents are headings and text. REV-012 and REV-014 are the gaps in the command-line rules. They are go-live advisories. They are not a reason to withhold this handoff.
