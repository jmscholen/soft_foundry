# Rollback

## Trigger conditions
`soft-foundry ci` fails on main after merge; the cap or approval check parks or fails a change wrongly and the cause cannot be fixed by adjusting the workflow.yml values; a released gem refuses records it should accept.

## Procedure
Revert the merge commit on main through a pull request, release a patch version from the reverted tree, and run `soft-foundry update --yes`. For a wrong value only (cap, must caps, default waivers), change the value in workflow.yml through a small change record instead of reverting.

## Data considerations
Records created with `rules: 2` stay valid under the reverted gate: it reads only criterion ids and ignores tier, person_checks, blocked_by, outside_change, run_phases and the new human_decisions boundaries. A record parked at awaiting_human by the cap is un-parked by a person setting status back and recording the decision, as today.

## Time to recover
Under one hour: a revert PR, a tag, and an update.
