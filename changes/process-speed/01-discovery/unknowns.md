# Unknowns

| Unknown | Impact if wrong | How to resolve | Blocking? |
| --- | --- | --- | --- |
| Exact definition of a "remediation round" (reopen entries resetting remediate vs `Record <slug> remediate` seals, and whether a first remediation reached without a reopen counts) | The cap fires one round early or late | Specification fixes the definition; readme-workflow-visuals history (8 remediate seals, reopen entries naming remediate, one verify reopen) is the worked example | no |
| Which paths count as "documentation only" (README.md is not in the DOCS group `docs/**`) | A README-only remediation still reruns the full tail, or a code change slips through as docs | Specification names the globs: DOCS, top-level Markdown, and the change record; code globs (APP, TESTS, INFRA) and CONTROL_PLANE excluded | no |
| Starting must caps per risk (intake assumption low 3, medium 8, high 15) | Caps too low force real requirements into should; too high recreate the problem | Maintainer confirms at specification approval | no |
| How a person un-parks a capped change (edit status by hand, or a command) | A parked change has no clear way forward | Specification decides; today parked changes are un-parked by hand | no |
| Interaction of the round cap with `phase run`'s automatic reopen of a stale remediate phase | An automatic reopen could consume or bypass the cap | Plan traces `PhaseRunner#stale_reason` and covers it with a test | no |
| Baseline suite result at 623a98c with provider keys and SOFT_FOUNDRY_PHASE unset | Later failures could be blamed on this change | Recorded in the handoff when the background run finishes | no |
