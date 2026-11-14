# Specification Readiness

## Blocking unknowns
None. The rows in 01-discovery/unknowns.md are resolved as follows: a round is one seal of remediation, and the plan picks the counting source with the worked example as its test (REQ-002); documentation is DOCS plus top-level Markdown plus the record (REQ-011, REQ-012); must caps start at low 3, medium 8, high 15 and are confirmed by the maintainer's approval of this specification (REQ-004); a capped change is un-parked by a person recording a human_decisions entry, with no new command (REQ-003); the automatic reopen by `phase run` is covered by AC-003; the baseline suite passed (DISC-001).

## Untestable criteria
None. Every criterion is a command or gate run on a fixture with an observable exit code, printed line, file content or metadata field, except AC-016, an inspection of skill text against REQ-013, as on earlier changes.

## Ready for threat modeling and planning
Yes, once the maintainer's approval of the must list (AC-001, 002, 004, 005, 006, 007, 008, 009, 010, 015, 017, 018) is recorded under human_decisions. The gate does not yet require that approval; this change records it anyway, since it is the behaviour being built.
