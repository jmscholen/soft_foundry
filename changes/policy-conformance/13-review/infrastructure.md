# Infrastructure Review

## Scope reviewed
No Infrastructure as Code is present in or modified by this change (`.ai/repository.yml`: `infrastructure.detected_or_not_applicable: NOT_APPLICABLE`). The only deployment artifact is the gem. The new files under `.ai/` (`rules/policy-conformance.md`, `skills/review/template/policy-conformance.md`) and the edited templates are picked up by the gemspec's `.ai/**/*` glob and by `Installer::Source#entries`; `.ai/repository.yml` stays in the installer's `EXCLUDED` list, so a governed repository keeps its own profile.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-020 | info | `soft_foundry.gemspec`, `lib/soft_foundry/installer/source.rb` | The standard, the template, and the edited `templates/repository.yml` (with its `policies:` block) ship with the next gem build without further work; a repository running `soft-foundry update` then `init` receives them, and its next `onboard --maturity scan --reassess` writes the `policies:` block. | `.ai/rules/infrastructure.md` (not applicable; noted for completeness) |

## Conformance
N/A: no infrastructure is present or modified. Examined the packaging path to confirm the new control-plane files reach installed repositories.
