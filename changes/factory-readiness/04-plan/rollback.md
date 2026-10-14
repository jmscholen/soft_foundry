# Rollback

## Trigger conditions
- `ci` on `main` fails after merge for a reason inside this change (an eval case that does not hold on the runner, a lint that rejects the shipped workflow).
- An application repository cannot work a change under block mode because a legitimate path is refused and the override is not acceptable to its maintainer.

## Procedure
- Revert the merge commit (`git revert -m 1 <merge>`); the gem is not published to RubyGems, so `soft-foundry update --yes` on the previous tag restores application repositories. Per machine, `SOFT_FOUNDRY_GUARD=warn` is the immediate relief for a refused path while the permission set is corrected through a change.
- A single failing eval case is fixed or removed through a change record; `eval --case` isolates it.

## Data considerations
N/A. Records are untouched by rollback; `.ai/repository.yml` written by this discovery stays valid (it describes evidence, not the version).

## Time to recover
Minutes: one revert and a CI run.
