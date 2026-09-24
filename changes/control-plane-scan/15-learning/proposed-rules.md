# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| Promote `sanitize-transcripts-before-they-become-evidence` (0.85) | `.ai/rules/learned.md` via `soft-foundry learn promote` | REV-005 | As in `instincts.yml` |
| Promote `exempt-closed-evidence-in-policy-not-by-editing-it` (0.85) | `.ai/rules/learned.md` via `learn promote` | the canary exemption | As in `instincts.yml` |
| Run `scan` as part of `ci` | `lib/soft_foundry/cli.rb` (through a change record) | REV-020 | `ci` runs `check`, every open record's gates, and `scan` over closed records' evidence |
