# Deviations From Plan

There was no plan phase (stepped over by default at low risk). One deviation from the specification's wording, and one test correction, are recorded here.

## DEV-001: AC-002's third state is tested at the cap and one round above it
AC-002 lists "a third remediation round with no cap decision" among the states that must fail the gate. The reopen is refused at two rounds (the cap), and the `remediation within cap` gate check fails once a third round exists with no decision. The test asserts both: the refused reopen at two rounds, then the failing check at three. No requirement is affected; this is how the gated track behaves too. No approval needed.

## DEV-002: one assertion's setup was corrected after the RED commit
`test_a_light_record_is_held_to_the_remediation_cap` at the RED commit (`a53ec00`) expected the gate check to fail at exactly two rounds. Two rounds is at the cap, not beyond it, so the check passes there by design (process-speed REQ-003). The GREEN commit adds one more sealed round before that assertion. The assertion itself is unchanged.

## DEV-003: one existing assertion was changed
AC-009 (should) says every existing test passes without its assertions being changed. `LifecycleTracksTest#test_repository_declares_both_tracks_with_gated_as_default` asserts the exact list of tracks this repository declares, `gated` and `iterative`. Adding a track makes that list three long, so the assertion now reads `gated iterative light`. Every other existing test passed unchanged in the full run (951 runs, this one failure). AC-009 is met except for this assertion; REQ-011 is not affected, since the gated and iterative tracks behave as before. For the maintainer to note at acceptance.
