# Consolidated Review

Commit reviewed: `5b2a028811fedb857d4f7a4e8c5a41a81c430340`. A fresh session, review skill only, guard in block mode throughout. Requirements come from `00-intake/request.md` (REQ-GDH-001 to 005); the specify phase is waived and `02-specification/` holds the unfilled template.

## Functional
REQ-GDH-001 holds: both hook files equal the installer's constants, and the committed hook refused this session's one shell command that named them. REQ-GDH-002 holds for every checkable claim except the unquoted `off` (EVAL-F-001) and a scope imprecision (REV-GDH-002). REQ-GDH-004 is complete in coverage: every item intake lists is in the README and the user page, with real code lines behind each claim. One instruction is wrong in effect: the file override `mode: "off"` the text recommends is deleted by the first shell command's post-call check, because the pre-call hook skips the baseline in off mode and the post-call hook does not (REV-GDH-001, major; probed in `evidence/off-override-probe.txt`). REQ-GDH-005 holds at HEAD. REQ-GDH-003 is unreadable by this skill (REV-GDH-007). Minor: REV-GDH-003 (the log gets a `tamper` line with nothing restored when the baseline is missing), REV-GDH-004 (the Grok post-call claim is unevidenced). Informational, recorded as minor: REV-GDH-008 (a gate test writes the override unquoted and so tests an override that is not in effect).

## Architecture
Conforms. The maintainer commit outside the lifecycle and the session's metadata step are the deviations implementation named; both are accepted (REV-GDH-009): no skill may write those files, the commit is labelled and read as REQ-GDH-001 to 003, and the precedent is release-0-23-0. The three descriptions (policy header, README, user page) agree with one another.

## Security
Conforms. Block mode unchanged; no control weakened; the published list of limits is the accepted residual of factory-readiness. REV-GDH-001 fails toward the stricter mode and exposes nothing; its security-relevant edge is that `SOFT_FOUNDRY_GUARD=off` reverts an uncommitted edit of the policy at the first shell command (probe case C).

## Accessibility
Conforms with advisories. One minor advisory, REV-GDH-006: the README section's six sub-topics are bold lead-ins, not headings (WCAG 2.2 1.3.1, 2.4.6), so they are not navigable by heading; the user page has the same content under real headings. CLI output examined carries the outcome word beside the glyph and says what to do next.

## Policy conformance
N/A, with the examination recorded: `surfaces.policy` is false, the repository profile records privacy, security and terms as `NOT_APPLICABLE` with rationales, and the change adds no collection, recipient, retention or promise. No policy text change is owed.

## Infrastructure
N/A: no infrastructure as code or pipeline is present in or modified by the change; `infra/` and `.github/` are identical to `main`.

## Operations
Conforms with REV-GDH-001 (the override procedure) and one minor finding, REV-GDH-005: the protected header still lists `off` unquoted and says nothing is guarded outside a change branch, a maintainer edit owed. Informational, recorded as minor, REV-GDH-010: `doctor` reports presence, not the matcher; documented, non-goal here.

## Blocking findings
None. REV-GDH-001 is major, not blocking: the misbehaviour fails toward the stricter mode, the variable route to `off` is documented beside the file route and works when no override file and no uncommitted policy edit exist, and the owner's scope excludes code (REQ-GDH-005). It does need a decision before go-live, because the deliverable of a documentation change is its text and this text tells a maintainer to do something the tool undoes. Two ways to clear it: a documentation correction in this record (say the file override cannot hold `off` while the hook is installed, give `SOFT_FOUNDRY_GUARD=off` as the way, note that an uncommitted policy edit is reverted under it), which returns the record through remediation to verify; or approval with residual risk naming the correction and the code fix (record the baseline in off mode, or skip the post-call check in off mode, in `cli.rb` `guard` and `guard_after`) as conditions for a later record. The judgment decides.

## Residual concerns
- REQ-GDH-003 (`.ai/harness-evals/README.md`) is checked by nobody in the lifecycle; the maintainer reads it at merge (VER-002, EVAL-F-004, REV-GDH-007).
- The `cd` plus redirection refusal (EVAL-F-002) is documented as current behaviour; the record that fixes it revises README, the user page and FAQ-GDH-003 (DOC-F-004).
- The guard disengages at status `judged`, so the learn phase runs unguarded (REV-GDH-002); a code decision for a later record.
- The live-eval invocation rests on factory-readiness EVAL-004, the only run of `eval --live` in either record (DOC-F-002 a).
- `11-faq-index` and `12-observability` are pending and unwaived; the FAQ records are ready for the index phase (DOC-F-006), and the observability phase has no service to describe. Judgment should say how each is disposed.
- The gate's AC-001 placeholder (VER-004, EVAL-F-005) must be set aside in the judgment's `criteria_not_covered` with the waiver as the reason.
