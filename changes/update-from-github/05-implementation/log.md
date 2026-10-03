# Implementation Log

## Changes made
1. RED `ae3e48b`: `test/updater_github_test.rb` and additions to `test/cli_update_test.rb`.
2. GREEN `b7764e2`:
   - `lib/soft_foundry/updater.rb`: GitHub's latest release instead of RubyGems; `Release`; `parse_release`; install from the attached gem or from the tagged source, under `RbConfig.ruby`; injectable HTTP, downloader, and runner.
   - `lib/soft_foundry/cli.rb`: after an install, the `init` hint when this repository's `.ai/manifest.yml` was written by another version; help text.
   - `.github/workflows/release.yml`: a `v*` tag becomes a release with the gem attached, after the version check and the tests.
   - `.ai/repository.yml`: `deployment_targets: [github-releases]`.
   - `lib/soft_foundry/version.rb`: 0.17.0.
   - `README.md`: the Updating section.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
- The first evaluation of the install path had no release to install. The repository's `main` source tarball stood in for one (its `version.rb` said 0.16.0), which exercised download, extraction, build, and install for real.
