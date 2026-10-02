# Assumptions

## Explicit assumptions
- Performed directly by the interactive session that implemented the change, not by fresh-context agents per phase; the review is not independent and the advisory says so.
- Stacked on `ui-server`, which is stacked on `ui-snapshot`. It edits `snapshot.rb` and the page files those changes introduced; their records measure staleness on their own branches.
- No new attack surface: the server's routes, headers, and refusals are untouched. The one security-relevant behaviour, that record text in the new views is text, is observed with hostile strings in evaluation (a time of `<b>not a time</b>`, a decider named `<i>Ada</i>`).
- Budget caps are shown as policy. Whether they apply depends on billing mode, which is a fact about the machine running the work, so the page says "when usage is metered" rather than detecting it.

## Ambiguities resolved
- A graph or words for the loops: words. Five edges are clearer as five sentences than as arcs over sixteen boxes, and they read correctly to a screen reader.
- Where check descriptions come from: the workflow data, fetched once; a change drawn before it arrives is redrawn when it does.

## Ambiguities that block safe progress
None.
