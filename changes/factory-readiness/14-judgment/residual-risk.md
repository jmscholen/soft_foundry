# Residual Risk

| Risk | Source | Likelihood | Impact | Accepted by | Mitigation owed |
| --- | --- | --- | --- | --- | --- |
| Same-user agent with a shell defeats the post-call restore (detached writer, policy and baseline rewritten together, weak policy committed with baseline deleted) | ATK-F10, REV-002, REM-005 | Low | Medium: guard downgraded to warn for a session | Judgment (this phase), following REM-005 and the prior panel-phases decision of no OS sandbox | Traces in guard log, git history, PR diff; OS sandbox is out of scope |
| Docs and installation owed are not applied; this repository's hooks lack the PostToolUse entry; doctor does not detect it | REV-001, REV-010, EVAL-F5 | High (currently true) | Medium: restore and Grep/Glob guard inactive in existing repositories believing they are in block mode | Not accepted; open condition | Maintainer: README guard section, enforcement.yml header, rerun `hooks install --claude`; consider a doctor check |
| Documentation and FAQ phases not run (not waived) | 10/11 pending | Certain | Low | Judgment, conditional on maintainer decision | Run phases or record README edit as documentation |
| Root-wide reads reach eval cases | ATK-F9, REV-003 | Medium | Low: tailoring to cases still faces fresh-context review and attack | Judgment | None; documented limit |
| Guard code editable by implementer when dogfooding | ATK-F12, REV-005 | Low | Medium | Judgment | Review and attack catch a weakened guard |
| Self-attested handoff commit_sha | ATK-F3, REV-008 | Low | Low | Judgment | Git history; future gate comparison |
| Maintainer edit within 30 min of an interrupted shell call reverted; failing-Bash PostToolUse unverified | REV-011, REV-004 | Low | Low | Judgment | README: run `soft-foundry guard --after` or wait |
| Live eval fails by default without shell args; no suggested next step | EVAL-F1, REV-007, REV-009 | Medium | Low | Judgment | Document the shell args; add next-step text (WCAG 3.3.3 advisory) |
| Rails profile records `ruby` not rspec | EVAL-F2, REV-006 | Certain | Low | Judgment | Align wording or profile |
| Earlier intermittent live-case test failure under load, never root-caused | 06-verification | Low | Low | Judgment | Investigate if it recurs |
