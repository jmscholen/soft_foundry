# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| The workflow view reuses the gate strip and panel | A separate diagram component | One thing to learn: the same sixteen stops, showing requirement instead of state | Dashed edge and the word "Optional" mark optional phases |
| Loops as a list of sentences | SVG arcs between phases | Five edges; readable by everyone, nothing to draw or keep in sync | No picture of the loops |
| `over_cap` and `needs_approval` computed in the snapshot | Compare in the page | The comparison is policy logic; the page should only draw | Three booleans added to the data |
| An unusable time drops the event | Keep it at the end, marked | A timeline orders by time; an event without one is not on it. The iteration still counts in the track line | A journal entry with a mistyped time is silently absent from the timeline; the note above the list says times are as recorded |
| Caps shown with "when usage is metered" | Detect billing mode in the server | Billing mode belongs to whoever runs a phase, not to the viewer's machine | The page cannot say whether the cap is live for a given entry |
