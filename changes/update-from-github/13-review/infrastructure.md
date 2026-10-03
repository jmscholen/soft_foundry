# Infrastructure Review

## Scope reviewed
`.github/workflows/release.yml`, the one piece of infrastructure this change adds.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-017 | info | workflow | Runs on `v*` tags only; `contents: write` scoped to the job; fails unless the tag equals `version.rb`; runs the tests; builds; attaches with `gh release create --generate-notes`. | `.ai/rules/infrastructure.md` |
| REV-018 | minor | workflow | Pinned to major versions of `actions/checkout` and `ruby/setup-ruby`, like `ci.yml`. Pinning to a SHA is the stricter practice for a job that publishes. | Supply chain |
| REV-019 | minor | workflow | A re-pushed tag fails at `gh release create` because the release exists; that is the right outcome, but the message will be `gh`'s. | Operability |

## Conformance
Conforms.
