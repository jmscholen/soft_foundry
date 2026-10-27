# Assumptions

## Explicit assumptions
- `change new --type` and `--risk` accept the vocabularies already listed in the `metadata.yml` template comments; an unknown value is refused with the allowed list. Omitting them leaves `TBD` as today.
- The runner already reads the handoff after a session; marking `blocked` is a write the runner makes to the handoff it just read, recorded in `executed_by` notes or output, never an edit of another phase's evidence.
- Invisible-character guidance is skill text (under `.ai/skills/`) and shipped README text; it does not change what the scanner flags.
- The latest-state summary is derived from existing record files (metadata, handoffs, findings); it adds no new stored state.
- The access-control parity rule is a rule file plus repository profile keys; the existing `access_control` key from change A names the paths, and the gate checks only that the verification record states the protection state it ran with.

## Ambiguities resolved
- Scope is item 7 only. The maintainer split the field feedback into changes A, B and C.
- Nothing here is adopter-specific; the Rails examples in the report illustrate the case.

## Ambiguities that block safe progress
None. Open design questions (the exact `blocked` wording, the summary's command name and layout, how the parity state is recorded in the verification record) belong to specification.
