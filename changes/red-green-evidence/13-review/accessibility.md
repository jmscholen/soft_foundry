# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces command-line output (the `red evidence` gate line in its pass, fail, and skip forms; the `! warn verification:` advisory) and documents (the testing rule, the skill text, the template comment, the README section).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-013 | info | `lib/soft_foundry/gate.rb`, `advisory.rb` | Every new line carries its outcome as a word (`✓ pass`, `✗ fail`, `- skip`, `! warn`) and survives stripping non-ASCII bytes (EVAL-006). Failures name the check id first, then the hash, then the reason. | CLI rules 1, 3, 5 |
| REV-014 | minor | `lib/soft_foundry/advisory.rb` `red_evidence_notices` | About 180 characters on one line (EVAL-NOTE-001). Same follow-up as the earlier long-line findings. | CLI rule 5 |
| REV-015 | info | `README.md` section, `.ai/rules/testing.md` | The README shows the two fields in a fenced YAML block with comments and states the check's limit in the same paragraph as the check; the rule is one sentence per obligation. | Document rules |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable because the change renders no HTML, native, or document UI.
