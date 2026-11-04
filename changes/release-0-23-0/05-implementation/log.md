# Implementation Log

## Changes made
- `lib/soft_foundry/version.rb`: VERSION 0.22.0 to 0.23.0 (REQ-REL-001). It is the only tracked file that changes; `Gemfile.lock` is gitignored.

## Decisions
See decisions.md.

## Deviations from plan
None. The plan phase was waived; the steps follow intake and the release path in README.md.

## Challenges
None in the code. The test suite takes longer than a single foreground shell call allows, so it ran in the background.
