# Evaluation Plan

## Intent being proven
On a real machine with Claude Code, Codex, and Grok installed, `phase run review` without `--shell` after an Anthropic implementation chooses another provider and says why; `--shell` wins; an unknown provider is said plainly; a review recorded on the same provider is advised; and a major finding without a stated failure fails the review gate until one is named.

## Personas
The maintainer, running review and judgment through `phase run`.

## Journeys
`journeys.yml`, run by the real CLI against a scratch repository carrying this repository's control plane and the maintainer's real `PATH`.

## UI walkthrough evidence
N/A: nothing on the page changes; the advisory reaches it through the existing advisory list.

## Accessibility interaction
The new `shell:` and `! warn shell:` lines and the gate line read with non-ASCII bytes deleted (EVAL-005).
