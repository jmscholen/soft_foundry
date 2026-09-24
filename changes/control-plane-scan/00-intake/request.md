# Change Intake

## User intent
Fifth of the five additions from the ECC evaluation, agreed with "ok, lets do the 5 recommended additions": scanning the control plane as an attack surface. `soft-foundry check` verified structure and never read content. ECC's AgentShield treats hooks, MCP configuration, and agent files as inputs an attacker may have written. Soft Foundry's `.ai/`, `AGENTS.md`, `CLAUDE.md`, and every change record are exactly that: files an agent reads as instructions, and files anyone who can open a pull request can write. The learning-instincts review (REV-010) asked that the new `.ai/rules/learned.md`, agent-authored text loaded as a rule, be covered too.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-SCN-001.** A content scan over text finds four kinds: `invisible` (zero-width space, joiners, word joiner, byte order mark, soft hyphen, bidirectional embeddings, overrides, and isolates, tag characters), `secret` (AWS access key ids, OpenAI-style keys, GitHub tokens, Slack tokens, Google API keys, private key blocks), `override` (phrases such as "ignore all previous instructions", "disregard your instructions", "you are now a", "pretend you are", "do not tell the user", "hide this from the user", "new system prompt:"), and `fetch_exec` (`curl`/`wget` piped to a shell or interpreter, `sh -c "$(curl ...)"`, `eval "$(wget ...)"`, PowerShell download-and-invoke). Each finding names the path, line, kind, and a detail that never repeats a secret.  <!-- soft-foundry:scan-allow -->
- **REQ-SCN-002.** `invisible` and `secret` are errors everywhere. `override` and `fetch_exec` are errors under `.ai/policies/` and warnings elsewhere.
- **REQ-SCN-003.** A line carrying `soft-foundry:scan-allow` is exempt from `secret`, `override`, and `fetch_exec`, never from `invisible`. `.ai/policies/content-scan.yml` lists exemptions by path globs, optional kinds (never `invisible`), an optional substring the line must contain, and a required reason; `check` errors on an entry with no paths, no reason, or an unallowable kind.
- **REQ-SCN-004.** `soft-foundry check` scans `.ai/**`, `AGENTS.md`, and `CLAUDE.md` and reports each finding as `path:line kind: detail` at its level; errors fail `check`.
- **REQ-SCN-005.** Every complete phase's gate carries a `content clean` check over the files in its directory: errors fail it, warnings warn, none passes.
- **REQ-SCN-006.** `soft-foundry scan [paths...]` runs the scan over the control plane and every change record, or the paths given, printing findings with status words and a summary line, exiting 2 on errors and 0 otherwise.
- **REQ-SCN-007.** Binary files are skipped by a null-byte probe; text is scrubbed of invalid bytes before matching; unreadable paths are skipped.
- **REQ-SCN-008.** `README.md`, `.ai/README.md`, `.ai/schemas.md`, and `.ai/rules/security.md` document the scan, the levels, the marker, and the allowlist. This repository's own scan is clean of errors, with the one real finding (a deliberate canary key in a closed record's evidence) exempted by the first allowlist entry with its reason. The four instincts from learning-instincts at or above the threshold are promoted into `.ai/rules/learned.md` through this record, and the scan covers that file. Version 0.14.0.

## Constraints
- The scan reads and never writes.
- A finding's detail never repeats the matched secret.
- The allowlist is policy: protected from every skill's write set and changed only through a change record, with a reason `check` requires.
- Every line the scan prints carries its outcome as a word per `.ai/rules/accessibility.md`.
- Existing records keep passing the gate unless they hold invisible text or a secret; quoted attacks in old threat models and attack logs are warnings.

## Non-goals
- Semantic detection of injection. The pattern list is a floor; a phrased-around attack is not caught, and the review is where content is judged.
- Entropy-based secret detection. Shapes only; a high-entropy string with no known prefix is not flagged.
- Scanning application code. `APP`, `TESTS`, and `INFRA` are the governed repository's own; its own tooling scans those.

## Task classification
Security: a `ContentScan` module, a content pass in `check`, a gate check, a `scan` command, a policy allowlist with validation, a security rule line, documentation, tests, this change's own RED commit and learning phase, and the first instinct promotion.

## Initial risk
low. Read-only scanning; a new gate check that fails only on invisible text and secret-shaped strings; the first run over this repository found one canary and nothing else.
