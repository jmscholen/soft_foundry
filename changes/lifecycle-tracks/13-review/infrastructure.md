# Infrastructure Review

## Scope reviewed
No Infrastructure as Code is present in or modified by this change (`.ai/repository.yml`: `infrastructure.detected_or_not_applicable: NOT_APPLICABLE`). The only deployment artifact is the gem. The new `.ai/skills/exploration/**`, the edited templates, the `tracks:` block, and the policy line ship through the gemspec's `.ai/**/*` glob; `test/installer_test.rb` and `test/installer_source_test.rb` still pass, so the packaged set includes them and nothing traverses or symlinks.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-022 | info | `soft_foundry.gemspec`, `lib/soft_foundry/installer/source.rb` | A repository running `soft-foundry update` then refreshing its control plane receives the tracks block, the stage skill, and the new templates. A repository that keeps its older `.ai/workflow.yml` keeps working: `ControlPlane#tracks` synthesises a single `gated` track and `check` passes (tested by removing the block). | `.ai/rules/infrastructure.md` |
| REV-023 | info | `.ai/repository.yml` `environments:` | This repository's own development environment is recorded honestly as a local checkout against a scratch repository, with the test helper named as the mechanism; there is nothing to deploy. | `.ai/rules/infrastructure.md` |

## Conformance
N/A: no infrastructure is present or modified. Examined the packaging path to confirm the new control-plane files reach installed repositories and that older planes are unaffected.
