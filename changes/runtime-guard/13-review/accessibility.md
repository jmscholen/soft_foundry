# Accessibility Review

Standard: `.ai/rules/accessibility.md` (WCAG 2.2 AA for user interfaces; CLI output, document, and evidence rules). Cite the success criterion or rule in every finding.

## Scope reviewed
`surfaces.accessibility: true` is declared for this change, so this review is not N/A. The change produces command-line output (the guard's refusal and warning lines, the `hooks install`/`uninstall` confirmations, the `claude guard hook` doctor line, the `check` error) and documents (the policy file's comment, the README section, the `AGENTS.md` paragraph).

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-015 | info | `lib/soft_foundry/cli.rb` `guard`, `doctor`, `hooks` | Every line carries its outcome as a word beside the glyph (`✗ fail guard:`, `! warn guard:`, `✓ pass claude guard hook`) and survives stripping every non-ASCII byte (EVAL-010). The first full-suite run caught a mode line without a status word; it was folded into the check line. | CLI rules 1, 3, 5 |
| REV-016 | info | all CLI output | No escape sequences, no prompts; the guard is silent when it allows, so a screen reader hears only decisions that need attention. | CLI rules 2 and 4 |
| REV-017 | minor | `lib/soft_foundry/cli.rb` `guard` | The refusal line runs to about 190 characters (EVAL-NOTE-001). Line-oriented as the standard asks; the "the <skill> skill's permissions.yml does not allow it (mode: ...)" clause could move to a second indented line. Same follow-up as lifecycle-tracks REV-018. | CLI rule 5 |
| REV-018 | info | `.ai/policies/enforcement.yml`, README section | The policy comment states the rules in prose before the one key it sets; the README section has a fenced command block, one example refusal in a code block, and no images. | Document rules |

## Conformance
Conforms to `.ai/rules/accessibility.md` (command-line and document rules). WCAG 2.2 user-interface criteria are not applicable to this change because it renders no HTML, native, or document UI; what it renders is terminal text and Markdown, covered by the CLI and document rules above and exercised with the glyphs removed in EVAL-010.
