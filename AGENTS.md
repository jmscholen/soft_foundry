# Agent Bootstrap Contract

<!-- soft-foundry:begin -->
This file is the only required vendor-facing entry point. Canonical instructions live under `.ai/`.

1. Read `.ai/README.md` and `.ai/workflow.yml` before making changes.
2. Identify the current Git branch/worktree. The change slug is the branch name without a `change/` prefix; its record is `changes/<slug>/`.
3. If the record does not exist, create it with `soft-foundry change new <slug>`; never hand-copy templates.
4. Read `changes/<slug>/metadata.yml` for `current_phase`, then `soft-foundry change status` for gate state.
5. Classify task and risk using `.ai/policies/` and record them in `metadata.yml`.
6. Load only the current phase skill: its `skill.yml`, `SKILL.md`, `permissions.yml`, `requirements.yml`, `completion.yml`, and the phase directory's template-derived working files. Path groups such as `${APP}` and `${TESTS}` resolve through `.ai/paths.yml` and `.ai/repository.yml`.
7. Honor read/write/deny boundaries. A skill must not perform another skill's job to manufacture a passing outcome.
8. Never weaken requirements, alter another phase's evidence, inspect hidden harness benchmarks when denied, or redefine success because implementation failed.
9. When a phase is done, fill its `handoff.yml` (status, commit SHA, completed time, resolved model, outputs, findings) and run `soft-foundry gate <phase>`. A failing gate is fixed by redoing the work, never by editing evidence or the handoff.
10. Any implementation change invalidates downstream commit-bound evidence. Follow `transitions` in `.ai/workflow.yml`: remediation, observability code changes, blocking review findings, and a BLOCKED judgment all return to `verify`.
11. Never declare the change complete without a final judgment artifact.

If the host platform cannot technically enforce a permission, treat the declared restriction as mandatory policy and record the limitation in the phase handoff's `notes`.
<!-- soft-foundry:end -->
