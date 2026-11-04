# Assumptions

## Explicit assumptions
- 0.23.0 is the right number: gate hardening adds commands and checks, and the project takes minor bumps for those.
- Installed 0.22.0 was built on 2026-10-27, before `phase_seal.rb` was added on 2026-10-29, so main and the installed gem share a version number and differ in code.
- `.github/workflows/release.yml` and the updater still work; neither has run for a real tag since v0.17.0.

## Ambiguities resolved
- "Release" means the documented path: bump, merge, tag, GitHub release, `soft-foundry update --yes`. Not `gem push`.

## Ambiguities that block safe progress
None.
