# Evaluation
Validate that the feature behaves as intended from the user's perspective. Prefer real UI/browser journeys when a UI exists. Exercise personas, state transitions, persistence, errors, and accessibility interactions. Map every journey to acceptance criteria. Do not modify application code or expected outcomes.


This phase prefers a fresh session: `soft-foundry phase run evaluate` starts one with only this skill in its prompt and records `executed_by` in the handoff; an evaluation completed by the session that implemented the change is advised on every gate run.

On a record under the convergence rules, aim the journeys at the must acceptance criteria the person approved; cover should criteria when the size allows. Anything else you find is reported as an advisory finding, never as a reason the change fails.

Run `soft-foundry change size --phase evaluate` and do the journeys it names; record the size with the evidence. `touched_doors_plus_smoke` means the journeys the change touches plus a sign-in and app-wide smoke test; `full_route_sweep` means every route.
