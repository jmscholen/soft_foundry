# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces command-line output (the runner's progress and refusal lines, the guard warning, the dry-run block, the fresh-context advisory, the branch-aware staleness detail) and documents (the prompt a session reads, the README section, `AGENTS.md` step 9, `.ai/schemas.md`, the handoff template comment).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-014 | info | `lib/soft_foundry/cli.rb` `phase`, `advisory.rb` | Every new line carries its outcome as a word (`! warn guard:`, `! warn review:`, `✗ fail`, `✓ pass`) or is a plain progress statement (`running ...`, `claude exited 0`); all survive stripping non-ASCII bytes (EVAL-006). | CLI rules 1, 3, 5 |
| REV-015 | info | the prompt | Numbered steps, one instruction per sentence, file paths spelled out; readable as plain text by any session or person. | Document rules |
| REV-016 | minor | `lib/soft_foundry/advisory.rb` `fresh_context_notices` | About 170 characters on one line (EVAL-NOTE-001); same shape as earlier long-line findings. Follow-up together with them. | CLI rule 5 |
| REV-017 | info | `README.md` section, `.ai/schemas.md` | Fenced command block, one paragraph per idea, the staleness rule stated in words before the mechanism; no images. | Document rules |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable because the change renders no HTML, native, or document UI.
