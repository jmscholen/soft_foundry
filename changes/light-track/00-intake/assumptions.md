# Assumptions

## Explicit assumptions
- "The test suite" in the maintainer's light track is the verify phase; "one review" is the review phase; judgment stays because the tool refuses to close a change without one.
- On the light track, learning is optional like the other removed phases.
- A change on the light track may still run an optional phase by naming it under `run_phases`.
- This change itself runs on the gated track at low risk, because the light track does not exist until it merges.
- `surfaces.accessibility` is true: the change alters command output and documentation a person reads.

## Ambiguities resolved
- Which phases the light track keeps: specification, implementation, test suite, one review (maintainer, 2026-11-14).
- REV-004 and REV-005 are fixed in this change (maintainer, 2026-11-14).
- Evidence phases run on Claude (maintainer, 2026-11-14).

## Ambiguities that block safe progress
None. Two points are for the maintainer at the must-list approval: whether low risk is right for a change that adds a track, and whether light should later become this repository's default.
