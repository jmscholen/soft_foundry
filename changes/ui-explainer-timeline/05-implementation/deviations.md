# Deviations From Plan

1. The plan called this change "front end only". It also changes `snapshot.rb`: two findings from the earlier reviews (unusable times, checks for every phase) were due here, and the over-cap comparison belongs in the data layer. Each has a test. No requirement of the plan is dropped.
2. One test committed at RED already passed (`test_workflow_checks_cover_what_the_gate_runs_for_every_phase`): it characterises existing behaviour that the earlier review said was untested. It is not counted as failing-first evidence.
3. Two cosmetic edits (one sentence, one outline rule) were made after the browser observations and before GREEN; the observations log says so.

Each deviation records: what changed, why the plan could not be followed, which requirements are affected, and who must approve it. The maintainer approves these by merging.
