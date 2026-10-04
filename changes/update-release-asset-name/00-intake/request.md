# Change Intake

## User intent
"run the soft-foundry update command?" The first real release, v0.17.0, was tagged and `update --yes` against it failed twice, for two reasons the tests had not seen. This change fixes both so the command does what the previous change promised.

## Desired outcome
- REQ-UPD-007: a release's attached gem is saved under the name the release lists for the asset, not under the final address of the download. GitHub serves assets through a redirect to `objects.githubusercontent.com/.../<uuid>`.
- REQ-UPD-008: `gem install` and `gem build` run as the running Ruby's own `gem` script (`RbConfig::CONFIG["bindir"]/gem`), not `ruby -S gem`, which resolves to whatever `gem` is first on PATH: under asdf, a shim for a different Ruby when run outside this repository.
- REQ-UPD-009: with both in place, `update --yes` run from the home directory installs the real v0.17.0 release, and the installed command then reports itself up to date against GitHub.

## Constraints
As `update-from-github`: no shell, three-way version agreement, HTTPS only.

## Non-goals
- Repairing the installed 0.17.0's own updater: it has the defects, so the step to 0.17.1 is made from a checkout; from then on the command updates itself.

## Task classification
fix

## Initial risk
low. Two lines of behaviour in a path that already refused anything mismatched; the failure mode was refusing a genuine gem, not accepting a wrong one.
