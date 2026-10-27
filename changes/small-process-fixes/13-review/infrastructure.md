# Infrastructure Review

## Scope reviewed

`.ai/rules/infrastructure.md`. Repository profile `infrastructure.iac.tools` is empty. Deployment target is GitHub releases. CI is `.github/workflows/ci.yml`, which this diff does not modify. The diff contains no Terraform, OpenTofu, Pulumi, CloudFormation, CDK, or other infrastructure-as-code. No plan, apply, state, IAM, network, or secret material is involved.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| | | | None. | | |

## Conformance

N/A. No infrastructure-as-code is present in the repository and none is modified by this change. The infrastructure rule's plan, replacement, IAM, state, and drift checks have no resource to apply to.
