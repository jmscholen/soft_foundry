# Assumptions

## Explicit assumptions
- Performed directly by the interactive session that implemented the change, not by fresh-context agents per phase; the review is not independent and the advisory says so.
- The three messages were taken together as one request: links everywhere, each with a popup, each popup naming the file. They arrived while the first was being built and were folded in.
- "Where the reference is located" is read as the path of the file that is the reference's source of truth, relative to its repository, since the page cannot open files.
- Stacked on `ui-repositories`.
- The test for this change was written after the implementation, not before: the work was page-only and the page has no runner, so the only possible test is a static one; it was added with the GREEN commit and there is no RED commit. The advisory will say no failing-test-first evidence exists, which is accurate.

## Ambiguities resolved
- What counts as a reference: a change, a phase of a change (a gate), a phase of the lifecycle, a repository, a commit. Not a skill (no page), not a file (not served), not a check name (explained in place).
- Phase names in free text: only `NN-name` directory forms are linked, because the ids are common words.

## Ambiguities that block safe progress
None.
