# Assumptions

## Explicit assumptions
- Performed directly by the interactive session, not fresh-context agents; the review is not independent and the advisory says so.
- Follows `update-from-github`, closed and merged; a merged change is reshaped by a new change, so this is one.
- The evaluation that mattered was against the real release from the home directory, which is where the previous change's "first tag is the real test" note pointed.

## Ambiguities resolved
- Why `RbConfig::CONFIG["bindir"]/gem` and not `Gem.bin_path`: the `gem` script ships with every Ruby in its bindir; no lookup is needed.

## Ambiguities that block safe progress
None.
