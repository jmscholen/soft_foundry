# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| Sibling-path parity for exit status | `.ai/rules/coding.md` (or the implementation skill's SKILL.md) | REV-001 | When a change alters what a command returns or exits with, list every caller of the helper and every sibling command path (single and parallel, interactive and runner) and state in the decisions record how each one is covered. A note that a path "already handles it" must say whether it means the printed result or the process status. |
| Option-form parity in CLI specifications | `.ai/skills/specification/SKILL.md` | REV-002, ATK-004 | A specification that adds a command option states the accepted spellings (spaced, equals, repeated) and what each does. An unrecognized spelling is refused with a message; it is never ignored. |
| Summary views never collapse an unexpected shape | `.ai/rules/coding.md` | REV-003, ATK-001 | Display code that summarizes a record field handles a value of an unexpected type by printing it escaped, or marking it unreadable. It never prints an empty-state word such as "none" for a value it did not understand. |
| Tests clear runner environment | `.ai/rules/testing.md` (create only if the rules directory has no home for it) | VER-001, REV-009 | A suite must clear `SOFT_FOUNDRY_PHASE` and other runner-set variables in setup, so it gives the same result inside and outside a phase session. |
| Follow your own guidance | `.ai/skills/review/SKILL.md` | REV-007 | When a change adds guidance to skill text, review checks the change's own files against it. |
