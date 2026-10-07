# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| PROP-001 | `.ai/rules/testing.md` | REM-001 | "When code builds a command line for an external program, at least one test or evaluation journey runs that program with the built arguments; a test that only compares the argument array does not count." |
| PROP-002 | `.ai/rules/security.md` | REV-SEC-001 | "Quote or re-validate every value at the point it is placed into a shell command, a path, or markup, even when it was validated on the way in." |
