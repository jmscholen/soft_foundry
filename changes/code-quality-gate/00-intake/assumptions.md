# Assumptions

## Explicit assumptions
- This change runs on the light track (the maintainer's decision of 2026-11-14 for the tool's own changes) at medium risk. The new phase does not exist until this change merges, so this change does not run it on itself.
- The phase id is `quality`, its skill is `code-quality`, and its directory is `06a-code-quality`. The directory name sorts between `06-verification` and `07-evaluation` without renumbering the directories existing records already have.
- "Records that already exist" are told apart by the `rules` number in `metadata.yml`: `change new` writes a higher number from this change on, and the phase is never asked of a record with a lower number or none.
- A text-only change (documentation and the change's own record) has nothing for the phase to read; the phase may be completed there with a statement of what was examined.
- The phase prefers a provider other than the one that implemented the change, as review does, and the maintainer's instruction to run evidence phases on Claude still decides which shell is used here.
- `surfaces.accessibility` is true: the change alters command output and documentation a person reads.

## Ambiguities resolved
- Position, authority and where it applies: the maintainer's three answers of 2026-11-15, quoted in request.md.
- "Other performance criteria" is read as performance and resource use on paths the feature exercises, not a general benchmark.

## Ambiguities that block safe progress
None. For the maintainer at the must-list approval: whether medium risk is right, and whether the four blocking classes are the right ones.
