# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| PROP-001 | `.ai/rules/security.md` | REV-SEC-001..015 | "A change that runs agent sessions states their trust boundary in its threat model: what the sessions are trusted not to do, and what the tool itself observes and refuses." |
| PROP-002 | `.ai/rules/security.md` | REM-002, REM-003 | "Enforce what an untrusted step may change by observing the result (before and after), not by parsing the step's commands." |
