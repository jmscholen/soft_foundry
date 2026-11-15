# Deviations From Plan

The plan phase is waived (low risk); the steps follow intake.

1. **Maintainer commit outside the lifecycle.** `b9f4d7c` changed `.claude/settings.json`, `.codex/hooks.json`, `.ai/policies/enforcement.yml`, and `.ai/harness-evals/README.md`, which no skill may write. It was made on the owner's instruction ("Do it", in reply to being told these conditions of approval were open) before `change new`, so no record's guard applied. Requirements affected: REQ-GDH-001..003. Approver: review and the maintainer at merge.
2. **The person's metadata step made by the session.** The guard refuses `metadata.yml` to the intake skill; the waivers in `00-intake/skipped_phases.yml` and `surfaces.accessibility: true` were copied into it by the session on the same instruction, as the release-0-23-0 record shows the person doing. Approver: review.
