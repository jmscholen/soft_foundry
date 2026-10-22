# Specification Readiness

## Blocking unknowns
None. The discovery unknowns (scope syntax, location of shared core and access-control globs, unclaimed paths, dirty worktree, location of the full-suite record, access-control computation, diff base) are each closed in specification.md. Remaining non-blocking notes: exact key names and the size command's name are left to planning; harness-eval case contents were not read (denied) and are owned by implementation.

## Untestable criteria
None. AC-001 to AC-022 each state a given, when and then observable through gate, check or command output or git invocation counts, and each maps to at least one requirement.

## Ready for threat modeling and planning
yes. Security surface is declared and the main risk (stale evidence passing) has requirements REQ-003, 013, 014, 016.
