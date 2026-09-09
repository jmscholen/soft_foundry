# Infrastructure as Code Standard

Infrastructure is part of the application specification and is reviewed with the same rigor as application code.

## General

- Detect and preserve the repository's existing IaC tool and conventions. Do not migrate Terraform to OpenTofu, OpenTofu to Terraform, Pulumi to another system, or introduce a second IaC system without an explicit approved change.
- IaC must be declarative, reviewable, repeatable, and safe to plan before apply.
- Never run production `apply`, `destroy`, state mutation, IAM escalation, DNS cutover, database destruction, or equivalent irreversible operations without required human authorization.
- Do not commit secrets, plaintext credentials, private keys, generated sensitive state, or provider credential files.
- Remote state, locking, encryption, retention, and access control must be appropriate to the environment.
- Prefer least-privilege IAM and narrowly scoped network rules; wildcard privileges require documented justification.
- Changes must consider blast radius, replacement behavior, dependency ordering, rollback/recovery, drift, and multi-environment effects.
- Production-impacting resources should have meaningful tags/labels/ownership metadata where the provider supports them.
- Important infrastructure failure modes must be observable through logs, metrics, alarms, health checks, or equivalent controls.
- Do not silently import, delete, replace, or detach existing resources merely to make a plan converge.

## Terraform and OpenTofu

- Honor repository-required versions and provider constraints.
- Run formatter and validation checks using the repository's chosen binary (`terraform` or `tofu`).
- Inspect the plan before considering infrastructure verification complete.
- Treat resource replacement, deletion, IAM expansion, public exposure, state movement, and provider changes as high-signal review events.
- Use modules for meaningful reusable boundaries, not for every resource.
- Inputs and outputs must be intentional; mark sensitive values appropriately.
- Avoid provisioners and imperative local/remote execution unless there is no safer declarative alternative.
- State operations (`state rm`, `mv`, import/state surgery) require explicit reasoning and must not be used as a shortcut to hide drift.
- Prefer provider/data/resource references over duplicated hard-coded identifiers.

## Pulumi

- Respect the repository's Pulumi language and package-manager conventions.
- Do not use application-language flexibility to hide imperative infrastructure side effects.
- Use Pulumi configuration/secrets mechanisms for sensitive values rather than plaintext configuration.
- Preview changes before apply and treat replacements/deletions/public exposure/IAM expansion as high-signal review events.
- Use explicit dependencies only when dependency inference is insufficient.
- Avoid uncontrolled dynamic values or nondeterministic resource definitions that make previews unstable.
- Stack-specific configuration must not leak production secrets into source control.

## Generated or vendor files

- Do not hand-edit generated provider lock files, generated manifests, state snapshots, or synthesized artifacts unless the tool explicitly requires it.
- Generated files that are intended to be committed must be reproducible from committed sources and tooling.
