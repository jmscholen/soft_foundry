# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| Promote `read-the-host-contract-before-writing-an-adapter` (0.85) | `.ai/rules/learned.md` via `soft-foundry learn promote` | deviations.md | As in `instincts.yml` |
| Promote `say-policy-only-at-launch-when-no-hook-exists` (0.80) | `.ai/rules/learned.md` via `learn promote` | EVAL-003 | As in `instincts.yml` |
| `doctor` says "written, trust unknown" for the Codex hook | `lib/soft_foundry/cli.rb` (through a change record) | REV-018 | The guard line's codex state reads `written (trust it with /hooks)` |
