# Rollback

## Trigger conditions
- `ci` fails on `main` for a record that passed before the merge, for a reason that is the new gate and not the record.
- `phase seal` refuses or mis-commits in a flow the specification permits (a stacked change on its own worktree, a parallel run).
- A new check produces a false `fail` on a correct record that cannot be fixed by the record's author.

## Procedure
1. `git revert -m 1 <merge commit>` on `main`; rebuild and install the gem locally.
2. Adopters run `soft-foundry update` to receive the reverted control plane.
3. Open a change record for the fix; the reverted commit is the base.

## Data considerations
- Records sealed by the new command are ordinary commits; the old gate reads them as hand-committed handoffs.
- `branch_resolved` in a handoff and `criteria_not_covered` in a judgment are ignored by the old gate; nothing has to be removed.
- A script that learned exit code 3 from `gate` sees 0 again.

## Time to recover
Under an hour: one revert, one local gem install, one `update` per adopter.
