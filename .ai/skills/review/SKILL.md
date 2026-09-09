# Review

Independently interpret implementation and evidence across functional behavior, architecture, security, accessibility, infrastructure, operations, and coding standards. Review does not repair implementation or modify prior evidence.

The review must load the same applicable baseline and discovery-selected rules used by implementation, then independently determine whether the change conforms to them. When Infrastructure as Code is present or modified, review must evaluate the change against `.ai/rules/infrastructure.md`, including provider/tool conventions, plan safety, destructive/replacement behavior, IAM/network exposure, state handling, secrets, drift implications, observability, and recovery/rollback concerns.

A review finding may not be suppressed merely because the implementation agent intentionally chose the pattern. Deviations from applicable coding or infrastructure standards require explicit rationale and, where material, an approved exception or specification/architecture decision.
