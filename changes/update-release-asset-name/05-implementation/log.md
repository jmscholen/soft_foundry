# Implementation Log

## Changes made
1. RED `1da10bc`: `test/updater_github_test.rb` expects the download saved under the asset's name and the gem command by path.
2. GREEN `5dfa6b4`: `Release` carries `gem_name`; the downloader takes the name to save under; `Updater.gem_command` is `[RbConfig.ruby, bindir/gem]`; version 0.17.1.

## Decisions
See `decisions.md`.

## Deviations from plan
None beyond what `deviations.md` records.

## Challenges
The second defect (the `gem` shim) only showed after the first was fixed, and only from a directory outside this repository. The earlier change's evaluation had run the install path from inside the repository, where the shim resolves to the right Ruby.
