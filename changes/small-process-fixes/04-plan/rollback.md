# Rollback

## Trigger conditions
Suite or `check` regressions after merge; the runner marks a handoff blocked wrongly; `protection stated` fails on a repository that should be not applicable; summary crashes on a valid record.

## Procedure
Revert the merge commit on main (or the individual commits; they are ordered so each stands alone) and reinstall the previous version, 0.21.0, locally. Records created meanwhile stay valid because every new field is optional. A handoff the runner already marked `blocked` is a valid status: redo the phase, or reopen it with `soft-foundry phase reopen`. No evidence file is edited by hand.

## Data considerations
N/A. No data store. `metadata.yml` entries written by `--type` and `--risk` use existing keys, so nothing needs removal. Optional `protection` fields in a `tests.yml` are ignored by the previous version.

## Time to recover
Minutes: one revert, one local reinstall.
