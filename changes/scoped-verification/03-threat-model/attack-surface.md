# Threat Model

The high-risk failure named in intake is stale or insufficient evidence passing silently. Every threat below is a way to reach it, or a way to make the new reuse and sizing features claim more than they know. Requirement references are to `02-specification/requirements.yml`.

## Trust boundaries
See `trust-boundaries.md` (TB-1 to TB-7). There is no authentication, tenant or object isolation: this is a local CLI, and the only authorization boundary is the runtime guard with each skill's `permissions.yml` and protected paths, unchanged by this change.

## Externally controlled inputs
- `scope` globs in a record's `metadata.yml`, written by the implementing session or a person (REQ-001).
- `shared_core` and `access_control` globs in `.ai/repository.yml`, written by a maintainer (REQ-002, REQ-010).
- Full-suite fields in `tests.yml`: tree hash, command, outcome, cited record slug (REQ-006).
- Recorded check size in verification, evaluation and attack evidence (REQ-011).
- Repository file names and the git history/refs (branch tips, rebased or squashed commits) that the diff is computed from.
- Other records under `changes/`, whose scopes and tests files are read when deciding "claimed" and when resolving a citation. A merged-in branch can bring a record the reader did not write.

## Authorization boundaries
- Execution sessions cannot write the profile, policies or workflow (TB-1). Declaration edits made by a person after the evidence commit stale the evidence (REQ-013).
- A session may declare scope for its own record; it must not be able to benefit by narrowing it after evidence exists (REQ-013) or by declaring so broadly that it claims paths for others (THREAT-003).
- Verification, evaluation and attack sessions cannot alter another phase's evidence; a citation reads, never writes, another record.

## Abuse cases
- AC-A1 Narrow scope after verifying, so a later code change in a now-excluded path leaves evidence current.
- AC-A2 Declare a broad scope on a forgotten or closed record so its globs "claim" paths and unclaimed-path staleness never fires for others.
- AC-A3 Cite a record whose recorded tree hash was typed rather than computed, or whose outcome was hand-edited to passed.
- AC-A4 Reuse a full-suite run while the worktree is dirty, with untracked or ignored files that change behaviour but not the tree hash.
- AC-A5 Record a smaller check size than the diff demands, or leave access-control globs undeclared to force the "smoke only" reading.
- AC-A6 Choose shared-core globs that look valid but match nothing (typo, wrong directory) so core changes never stale anything.
- AC-A7 Force git errors (deleted branch, unknown commit, shallow clone, missing tree) hoping the check reads "no change".
- AC-A8 Exploit a squash or rebase merge so the tree hash matches by coincidence or differs unexpectedly.
- AC-A9 Supply a glob or slug with path traversal, an absolute path, option-like text, or shell metacharacters.
- AC-A10 Read a green gate as proof the suite passed.

## Injection / XSS / CSRF / SSRF / file risks
- Injection: glob strings and cited slugs flow into git arguments and filesystem lookups. Mitigated by argument-array invocation with no shell, `--` separation, slug validation against the record-name pattern, and refusal of absolute or `..` globs (REQ-014, REQ-015). Not N/A.
- Path traversal on citation: the slug resolves under `changes/` only; a slug containing separators or `..` is refused.
- XSS: the browser view (REQ-022) shows scope and staleness text derived from repository files. Values must be HTML-escaped as the existing view does; a glob such as `<script>` must render inert. Not N/A.
- CSRF: the view is read-only and loopback with a URL token; this change adds no mutating route, so N/A with that justification, to be re-checked if any is added.
- SSRF: N/A. No network request is added.
- File processing: YAML is loaded with the safe loader as elsewhere; malformed `tests.yml`, `metadata.yml` or profile values must produce a named failure, not a crash that reads as pass.

## Resource exhaustion and DoS
- A huge diff or thousands of globs must not multiply git invocations (REQ-024, THREAT-010). Glob matching cost against many changed files and many records is bounded and the record scan reads each record once.
- Pathological globs (deeply nested `**`) must not cause catastrophic matching.
- DoS of a local CLI is low impact; the real harm is the gate becoming slow enough to be skipped.

## Infrastructure exposure
None added (REQ-025). No service, port, credential or dependency. CI runs the same commands. The existing secret-shaped string scan of `.ai/` still covers the new policy file.

## Proposed attack cases
Listed per threat in `threats.yml` (`attack_case_required: true`); the attack phase should realise them as scripted repository fixtures:
- AC-X1 narrow scope after evidence (THREAT-001)
- AC-X2 stale-forgotten record claims all paths (THREAT-003)
- AC-X3 forged tree hash and outcome in a cited record (THREAT-004)
- AC-X4 dirty worktree and ignored file reuse (THREAT-005)
- AC-X5 smaller recorded size, absent access-control declaration (THREAT-006)
- AC-X6 blind shared-core glob (THREAT-002)
- AC-X7 git failure modes fail closed (THREAT-007)
- AC-X8 squash/rebase tree mismatch (THREAT-008)
- AC-X9 hostile glob and slug strings (THREAT-009)
- AC-X10 gate output wording (THREAT-011)
