# Assumptions

## Explicit assumptions
- The upstream repository is `https://github.com/jmscholen/soft_foundry`, taken from the gemspec metadata. It is read from the gemspec at runtime rather than hardcoded, so forks that publish their own gem point at themselves.
- "Prompt" means print guidance at the end of a failed command, not an interactive question. The CLI stays non-interactive; `soft-foundry report --open` is the explicit action that may invoke `gh`.
- A pull request is preferred over an issue only when the maintainer has a fix. The guidance offers both; the report file is the body for either.
- Classification is rule-based on exception type and origin: exceptions raised from `SoftFoundry::` code paths with an internal-invariant error class are soft-foundry-side; `ArgumentError`, refused targets, conflicts, and gate failures are target-side; provider `Result` errors are provider-side.
- This change lands after `init-command`, which introduces the classification hook it extends.

## Required test matrix
- a soft-foundry-side failure prints the upstream guidance and exits 4
- a target-side failure prints no upstream guidance
- a provider-side failure prints no upstream guidance
- `check` errors on a freshly installed control plane are soft-foundry-side
- `gate` failures on incomplete change work are target-side
- `soft-foundry report` writes a report containing no environment values or credentials
- `soft-foundry report --open` without `gh` prints the commands and does nothing else

## Ambiguities resolved
- Whether the tool should push the pull request itself: no. It prints or, on confirmation, runs the `gh` commands; the maintainer owns the fork and the push.
- Whether failures in the maintainer's own tests should trigger the prompt: no. Those are evidence, not Soft Foundry defects.

## Ambiguities that block safe progress
None.
