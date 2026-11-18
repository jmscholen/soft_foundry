# Deviations From Plan

There was no plan phase (optional on the light track). Deviations from the specification's wording are recorded here.

## DEV-001: a complete handoff may not carry a blocking finding
AC-003 says a well-formed blocking finding leaves the phase blocked. The check also fails a handoff whose status is complete while it carries a blocking finding, so the blocked state cannot be skipped by writing `complete`. This is stricter than the criterion's words and follows from REQ-005 and REQ-006. No approval needed.

## DEV-002: `run_phases` is honoured where the gate is off
REQ-004 says a change may run the phase by naming it under `run_phases`. Before this change `run_phases` only undid a default waiver at low risk. It now also makes the phase required for a record in a repository whose gate is off. Records made before the phase existed are still never asked for it.

## DEV-003: no harness eval case was added
A gate case for a blocking finding with no class would fit beside `review-finding-without-failure`. The implementation skill may not read `.ai/harness-evals/`, so none was written. The rule is covered by `test/code_quality_gate_test.rb`. For the maintainer to carry as a follow-up.

## DEV-004: existing assertions were changed in eight files
REQ-012 allows an existing assertion that counts or lists the lifecycle's phases or skills to be updated. The 14 tests that failed in the full run were corrected, in eight files (18 assertion lines in all, since some tests hold more than one): phase counts of 16 that are now 17 (`control_plane_test`, `snapshot_test`, `ui_server_test`, `cli_change_json_test`), lists of phases that now include `quality` (`control_plane_downstream_test`, `light_track_test`, two in `factory_readiness_test`), and the rules number `change new` writes, 2 to 3 (`process_speed_test`). The last is not a count or list of phases. It follows from REQ-004, which says `change new` writes a higher number from this change on. For the maintainer to note at acceptance.
