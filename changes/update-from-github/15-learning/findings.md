# Learning

## What this change taught us
- The repository's profile said `deployment_targets: [rubygems]` and the updater agreed, yet nothing had ever been published there. A profile claim nobody exercises drifts; the updater's own "not published to RubyGems yet" message had been saying so on every run.
- With no release to install, the repository's own `main` tarball was enough to run the whole download-build-install path for real. Looking for a stand-in that exercises the real code beats leaving a path to "the first tag will tell".
- Installing under `RbConfig.ruby` rather than `gem` on PATH is what makes "from any repository" true on a machine with several Rubies.

## Reviewer/evaluator/attack findings worth generalizing
- REV-009: when a tool installs what it downloads, the question is who can publish, not only how it downloads.

## Proposed deterministic checks
- A test that the profile's `deployment_targets` and privacy rationale agree with the updater's address.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
