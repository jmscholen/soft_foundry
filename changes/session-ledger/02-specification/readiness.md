# Specification Readiness

## Blocking unknowns
None. Codex's prompt-hook payload and whether `codex exec` fires it are documented but not live-verified (login expired); the design tolerates absent fields and a null Codex session ID, so neither blocks.

## Untestable criteria
None. AC-012's Codex branch is tested with a stubbed launcher and a seeded ledger rather than a live Codex turn; evaluation records that limit.

## Ready for threat modeling and planning
yes
