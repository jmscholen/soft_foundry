# Assumptions

## Explicit assumptions
- The threat is a same-user writer of the ledger file (session-ledger's threat model: the file is 0600 in a 0700 directory, so other users cannot write it). The fix narrows what lookup trusts; it does not try to authenticate lines.
- Valid session IDs from all three agents are UUID-shaped or similar plain identifiers, which the existing pattern `\A[A-Za-z0-9_-]{1,128}\z` accepts; `Shellwords.escape` leaves such values unchanged, so printed commands for real sessions do not change.

## Ambiguities resolved
- Skip, rather than show with a warning: a line that fails the check is not a session `record` would have written, and printing anything from it would reintroduce the paste risk.

## Ambiguities that block safe progress
None.
