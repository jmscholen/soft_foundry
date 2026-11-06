# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility` is true. The surfaces a person perceives in this change are documents and CLI output:

- `README.md`, section "Runtime enforcement: the guard hook" (lines 117 to 150 at HEAD) and the paragraph plus code block added to "Proving the gate: harness evals" (lines 398 to 402), read against the document rules (heading hierarchy, tables with a header row, descriptive link text, code blocks for commands).
- `docs/user/guard-hook.md` (new, 80 lines) and `docs/user/README.md` (a Pages table), read against the same rules.
- The header comment of `.ai/policies/enforcement.yml` (plain text in short paragraphs).
- CLI output quoted in the texts and produced by the unchanged commands: `hooks install`, `doctor`, the guard's refusals, `guard --after`. Evaluation EVAL-009 checked outcome words, stable prefixes, no ANSI escapes to a pipe, no prompts, and next-step guidance across the sweep; this session observed one refusal and one post-call message directly (`evidence/off-override-probe.txt`), both carrying the outcome word (`fail`, `warn`) beside the glyph and ending with what to do next or where the log is.

No specification requirement with `category: accessibility` exists because the specify phase is waived; the gate's advisory says so. The rules in `.ai/rules/accessibility.md` were applied directly.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-GDH-006 | minor (advisory) | `README.md` lines 127 to 141 | The guard section is one `###` heading followed by six sub-topics introduced by bold lead-ins (`**Rerun hooks install ...**`, `**Mode.**`, `**What each tool is checked against.**`, `**How a shell command is read.**`, `**The guard's own configuration**`, `**The post-call restore, and its limits.**`) rather than headings, and the last of these is a single paragraph of about 330 words. Bold text is not exposed as a heading, so a screen-reader user navigating by heading cannot reach "Mode" or "The post-call restore" and must read the section linearly. The README uses this convention elsewhere (line 85, for instance), and `docs/user/guard-hook.md` has the same content under real `##` headings, so a navigable version exists. | A screen-reader user looking for how to change the mode lists the README's headings, finds only "Runtime enforcement: the guard hook", and must read about 1,900 words to find the paragraph. Minor: the user page is the task-oriented text and is navigable. | WCAG 2.2 1.3.1 Info and Relationships, 2.4.6 Headings and Labels; `.ai/rules/accessibility.md` document rules (real heading hierarchy) |

Checked and conforming:
- `docs/user/guard-hook.md`: one `#` title, six `##` sections in reading order, no skipped level; one table with a header row, used for tabular data (message, cause, action); every command in a fenced code block; the link in `docs/user/README.md` reads "The guard hook", which names the destination (2.4.4 Link Purpose).
- The README's harness-evals addition: prose, then the invocation in a `sh` code block.
- Quoted CLI lines: `✗ fail` and `! warn` each carry the word; `installed`, `removed`, `pass`, `fail` carry the outcome; `doctor`'s fail line names the install command and every refusal names the tool, path, skill, mode and where the override is documented (CLI rules: outcome by word, error messages say what to do next).
- No image or diagram was added, so the alternative-text rule has nothing to apply to.
- No ANSI escape appears in any evidence file produced by this phase.

## Conformance
Conforms with advisories: one minor advisory (REV-GDH-006) on heading structure in the README section; the user page, the index, the policy header, and the CLI output examined conform to the applicable rules. Reported as a go-live advisory, not a reason to withhold this handoff.
