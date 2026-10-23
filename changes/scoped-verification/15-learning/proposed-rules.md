# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| Specification files must parse as YAML before lock | `.ai/skills/specification/requirements.yml` (completion check) or the specification SKILL.md | REC-001 | "Before locking, load every YAML file in `02-specification/` with a strict loader. A statement containing `: ` is quoted. A file that does not parse is not complete." |
| Record resolved facts, not only declarations, when a declaration selects what the gate measures | `.ai/rules/` (security or design standard for gates) | REV-001, ATTACK-F-006, ATTACK-F-007 | "When a gate takes its measurement base from a value the record's author writes (a branch, a path, a size), the evidence commit also records what that value resolved to at that commit. A later difference is a stale cause." |
| List changed paths without rename detection wherever the list decides staleness or size | `.ai/rules/` coding standard | ATTACK-013 | "Read git diffs for security or staleness decisions with `--no-renames`, so both sides of a rename are listed. Add a rename test." |
| Compare resolved identifiers exactly | `.ai/rules/` coding standard | ATTACK-016 | "After resolving a user-supplied slug to a directory, require the resolved name to equal the slug; do not rely on a case-insensitive filesystem lookup." |
| Loaders of record metadata rescue wrong-typed values and name the field | `.ai/rules/` coding standard | REV-004, ATTACK-018 | "A metadata value of the wrong type produces a gate line naming the field and the next step, not a Ruby exception." |
