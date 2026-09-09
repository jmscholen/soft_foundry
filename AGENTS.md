# Agent Bootstrap Contract

This file is the only required vendor-facing entry point. Canonical instructions live under `.ai/`.

1. Read `.ai/README.md` and `.ai/workflow.yml` before making changes.
2. Identify the current Git branch/worktree and its corresponding `changes/<change-slug>/` record.
3. If a change record does not exist, initialize it from the canonical phase templates before implementation.
4. Classify task and risk using `.ai/policies/`.
5. Load only the current phase skill: its `skill.yml`, `SKILL.md`, `permissions.yml`, `requirements.yml`, `completion.yml`, and template-derived working artifacts.
6. Honor read/write/deny boundaries. A skill must not perform another skill's job to manufacture a passing outcome.
7. Never weaken requirements, alter another phase's evidence, inspect hidden harness benchmarks when denied, or redefine success because implementation failed.
8. Bind generated evidence to the tested commit SHA. Any implementation change invalidates affected downstream evidence.
9. Do not skip lifecycle gates. Remediation loops back through verification, evaluation, and attack as applicable.
10. Never declare the change complete without a final judgment artifact.

If the host platform cannot technically enforce a permission, treat the declared restriction as mandatory policy and record the limitation in the change evidence.
