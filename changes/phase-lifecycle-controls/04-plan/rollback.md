# Rollback

## Trigger conditions
- A reopen or auto-reopen resets the wrong phases or loses history in a real record.
- A parallel run corrupts or loses updates to a record, or a lock hangs ordinary commands.
- The guard marker handling blocks legitimate single-phase sessions.
- `ci` on `main` passes a merged record it should fail (a released record with nothing owed), or fails records it should not.

## Procedure
1. Revert the change PR on `main` (single squash/merge commit), then rebuild and reinstall the gem locally. Adopters who ran `soft-foundry update` rerun it to take back the previous control plane.
2. Before or immediately after the revert, deal with records written by the new commands: any record with `status: released` must be closed (discharge the items, `change close`, or `change close --force` with the maintainer's decision) because the previous `ci` fails a merged change that is not `closed`. Keys `phase_reopenings` and `release` are ignored by the previous version and may stay.
3. A repository stuck behind a held lock needs nothing: the lock is a kernel `flock` released when the holder exits; the file under `.soft-foundry/locks/` can be deleted.
4. A record left half-reset (history entry present, some handoffs not reset) is repaired by running `phase reopen` again on the same phase with reason naming the earlier attempt (after rollback: by hand from the `previous` block in the history entry, which lists each phase's prior status, commit, completed time, and session).

## Data considerations
Only `metadata.yml` and handoffs are written, and every reset keeps the prior values in `phase_reopenings[].previous`, so a reset is reversible by hand from the record. Evidence files are never modified, so nothing is lost on rollback. Git history holds every prior version of the record.

## Time to recover
Minutes: a revert, a local gem rebuild, `soft-foundry update` in adopter repositories, and closing any released records.
