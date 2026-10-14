# Infrastructure Review

Standard: `.ai/rules/infrastructure.md`, applied because review must say so when infrastructure is in the change. It is not.

## Scope reviewed

`surfaces.infrastructure` is false. The diff from the pre-panel tree through `661b454` changes `lib/soft_foundry/panel.rb`, `lib/soft_foundry/cli.rb`, `test/panel_phases_test.rb`, `test/panel_remediation_test.rb`, `README.md`, and this change record. No Terraform, OpenTofu, or Pulumi. `.ai/repository.yml` records `infrastructure.iac.tools: []` and deployment as GitHub releases only. `.github/workflows` is not in the diff. No plan, state, IAM, network, or secret material was added.

## Findings

No findings.

## Conformance

N/A. Nothing in the change is infrastructure as code, and nothing a person deploys as a service changed. Provider conventions, plan safety, replacement, IAM, state, drift, and rollback in `.ai/rules/infrastructure.md` have no subject here.
