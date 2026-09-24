# Infrastructure Review

## Scope reviewed
No Infrastructure as Code is present in or modified by this change. The new template, policy, and rules file ship through the gemspec's `.ai/**/*` glob; `test/installer_test.rb` still passes. A governed repository receives an empty `learned.md` and the policy on its next control-plane refresh.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-017 | info | `.ai/rules/learned.md` on refresh | `init --force` would overwrite a governed repository's promoted rules with the shipped empty file if the manifest marks it Soft Foundry-owned. The installer's manifest logic treats a user-modified file as a conflict rather than overwriting, so promoted content is preserved; worth a test in the next installer change. | `.ai/rules/infrastructure.md` |

## Conformance
N/A: no infrastructure is present or modified.
