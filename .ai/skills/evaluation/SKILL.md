# Evaluation
Validate that the feature behaves as intended from the user's perspective. Prefer real UI/browser journeys when a UI exists. Exercise personas, state transitions, persistence, errors, and accessibility interactions. Map every journey to acceptance criteria. Do not modify application code or expected outcomes.


This phase prefers a fresh session: `soft-foundry phase run evaluate` starts one with only this skill in its prompt and records `executed_by` in the handoff; an evaluation completed by the session that implemented the change is advised on every gate run.
