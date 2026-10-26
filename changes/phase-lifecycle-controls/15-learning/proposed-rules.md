# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target | Motivation |
| --- | --- | --- |
| Add to `.ai/rules/testing.md`: a remediation fix for a reviewed defect carries a failing test committed before the fix, named as `red_commit`, same as implementation. | testing rules | VER-002: both remediation tests of REV-001 and REV-002 have no red commit. Reinforces `commit-the-failing-test-first`. |
| Add to `.ai/rules/architecture.md`: a predicate that more than one surface evaluates (CLI, API, page) is defined once and the other surfaces consume its result, not a re-implementation. | architecture rules | REV-002, REV-009: Ruby `strip` and JS `trim` disagree on U+00A0. |
| Add to `.ai/rules/errors.md`: a multi-file write that cannot be atomic orders its renames so a crash leaves the state that later checks refuse, and states the crash window in a comment. | errors rules | REV-001, REV-008. |
| Specification guidance: an acceptance criterion that says "all or nothing" across several files must say whether fail-closed is acceptable, or the plan must name a journal. | specification skill | AC-017 vs REV-008: the letter is unmet with no way for remediation to fix it. |
| Workflow: when a specification requires documentation or harness-eval cases, the plan names which phase writes them and the phase is not skipped as optional. | `.ai/workflow.yml` / plan skill | REQ-027, AC-050, REV-004, JUDGE-004: left undone because no phase with write access ran. |
