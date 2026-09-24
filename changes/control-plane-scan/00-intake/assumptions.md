# Assumptions

## Explicit assumptions
- Files an agent reads as instructions deserve the treatment a security scanner gives inputs: the same review that notices a wrong rule will not notice a zero-width character, and a secret in evidence is a leak regardless of who wrote it.
- Pattern lists are a floor, not a ceiling. The override phrases are the common forms; an attacker who rephrases is not caught, and that is stated. The secret shapes are the ones with recognisable prefixes; a bare high-entropy string is not caught, and that is stated.
- A quoted attack is legitimate in a rule, a threat model, or an attack log, so override and fetch-and-execute are warnings outside `.ai/policies/`, where no quotation belongs. A documented example key is legitimate too, so the in-line marker exempts secrets; invisible text has no legitimate use and is never exempt.
- Closed evidence cannot carry an in-line marker (editing it would alter evidence), so the policy allowlist exists for that case and requires a reason a reviewer can weigh.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, on the gated track, and the review and learning phases are run for it. That choice is recorded here rather than silently assumed.

## Ambiguities resolved
- Whether the gate should scan evidence directories or only required files: everything in the phase directory. A leaked key in a transcript is the case that matters most, and a quoted attack in a transcript is only a warning.
- What to do about this record's own transcript, which the journeys filled with a zero-width character and a canary key by design: the harness now renders invisible characters as their code points and masks key-shaped strings before the output becomes evidence, so what the tool printed is preserved in words and the evidence scans clean. Exempting our own evidence would have been the wrong lesson.
- What to do about the canary key the first scan found in `init-command`'s closed evaluation evidence: an allowlist entry naming the paths, the kind, the substring `sk-canary`, and the reason. The alternative, editing closed commit-bound evidence, is what anti-fudging forbids.
- Why the learning tests failed after the first promotion: the fixture copies this repository's `.ai/`, whose `learned.md` now holds real promotions; the tests reset it to the header. A real repository's ledger accumulates, and the tests must not assume otherwise.

## Ambiguities that block safe progress
None.
