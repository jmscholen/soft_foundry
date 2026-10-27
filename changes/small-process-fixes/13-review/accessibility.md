# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed

`surfaces.accessibility: true`. Nothing in this change renders HTML, a native view, or a document UI, so the WCAG user-interface criteria for keyboard, focus, contrast, and target size have no surface here. What a person perceives is command-line text and Markdown.

Examined in the source and against the evaluation transcript (`07-evaluation/results.md`, non-TTY, `NO_COLOR=1`):

- Refusal text from `ChangeRecord.vocabulary!` (`--type` / `--risk` unknown value), printed as `soft-foundry: <message>`.
- Success lines `type:` and `risk:` after `change new`.
- `blocked: <phase> has <n> blocking item(s); status set to blocked, redo the phase once they are resolved`.
- `warn: could not mark <phase> blocked: <reason>`.
- Every `change summary` prefix (`change:`, `phase:`, `phase-status:`, `findings:`, `blocking:`, `owed:`, `note:`), including `unreadable` and the unknown-slug error that names the known changes.
- `Display.safe` / `Display.list`, which the new lines use for recorded text.
- README section "Everyday shortcuts" (`###` with `####` subsections, the same level as the surrounding sections) and `.ai/rules/access-control-parity.md` (one table, header row present, no images).
- The three skill paragraphs, which are prose under the existing headings.

`ChangeSummary` never emits an ANSI sequence. `Display.safe` replaces control, format, and separator characters with `<U+XXXX>` ASCII. The new commands do not prompt. Outcomes are words (`blocked`, `unreadable`, `none`, the recorded status). The evaluation transcripts contain no escape bytes.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-008 | minor | `lib/soft_foundry/cli.rb` `mark_blocked` rescue | The line names the failure and the exception text, and does not say what to do next. The gate result is printed afterwards on the single-run path, so a person who reads the whole output still sees the phase fail. The `warn:` line itself is the line CI will search for. | `update_handoff` raises `TargetError` "lock busy" while marking `implement`. Stderr is `warn: could not mark implement blocked: lock busy`. The line does not say that the handoff was left as written or that the phase has to be redone. | `.ai/rules/accessibility.md` command-line rule (error messages name what went wrong and what to do next); WCAG 2.2 3.3.3 Error Suggestion; REQ-010 |

## Conformance

Conforms with advisories. The new CLI text meets the command-line rules: words for outcomes, no color, one prefixed line per fact, no prompts, and refusals that name the flag and the allowed values (WCAG 2.2 1.4.1 Use of Color and 3.3.3 Error Suggestion, applied to terminal text as the standard describes). The README and the rule file meet the document rules (heading hierarchy, one headered table, no image without text). REV-008 is the gap in the `warn:` line.

The `phase:` line also carries status, risk, and track in parentheses. Each fact is still words on a prefixed line, which is the layout AC-010 and the tests lock. It was read and is not a separate finding.
