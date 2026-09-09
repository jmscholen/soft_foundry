# `.ai/` Control Plane

`.ai/` defines HOW engineering work is performed. It contains lifecycle orchestration, skill contracts, policies, model profiles, maturity policy, repository capability assessment, runtime configuration, and deterministic checks. It should not become a duplicate home for product/domain documentation; canonical human/agent product documentation belongs under `docs/`.

A skill is a declarative agent definition. The harness loads its instructions, model profile, permissions, required inputs, template-derived working artifacts, tools, and completion gate into an isolated execution context.

The host may operate in either mode:

- **Enforced mode:** a harness technically constrains filesystem, commands, credentials, context, and model selection.
- **Compatibility mode:** a coding platform follows the same contracts from repository instructions when hard sandboxing is unavailable.

Canonical source templates under `.ai/skills/*/template/` and `.ai/templates/` are immutable workflow definitions. Copies under `changes/<change>/` are mutable execution records, created by `soft-foundry change new`. Schemas for the record and its per-phase `handoff.yml` are in `schemas.md`.

## Layout

| Path | Purpose |
| --- | --- |
| `workflow.yml` | Lifecycle phases, non-linear `transitions`, global rules, permitted judgments. |
| `paths.yml` | Named path groups (`APP`, `TESTS`, `INFRA`, `DOCS`, `CONTROL_PLANE`, `HARNESS_EVALS`) that skill permissions reference as `${GROUP}`. `repository.yml` may override a group with the repository's real layout. |
| `skills/<name>/` | One declarative skill per phase: contract files plus `template/` holding every file its completion gate requires. |
| `templates/` | Shared templates: the phase `handoff.yml` and the change `metadata.yml`. |
| `profiles/` | Capability profiles skills request; provider/model resolution is a runtime concern. |
| `rules/` | Coding and infrastructure standards loaded by implementation and checked by review. |
| `policies/` | Permission principles, protected paths, anti-fudging rules, human boundaries. Protected from every skill's write set. |
| `maturity.yml`, `repository.yml` | Maturity policy and the evidence-backed repository profile. |
| `harness-evals/` | Evaluations of the harness itself; denied to execution skills. |

`soft-foundry check` verifies this structure: every phase has a skill, every required file has a template, every permission references a known path group, no skill can write protected policy, and every skill denies reading harness evals. `soft-foundry gate` applies each skill's `completion.yml` to a change record.

Repository discovery is the only skill permitted to write inside `.ai/`, and only to `repository.yml`, because that file is evidence rather than policy.

## Repository maturity and gap analysis

`.ai/maturity.yml` is the canonical, machine-readable Soft Foundry maturity model. It defines levels, required capabilities, allowed assessment states, observability expectations, and scoring semantics. Agents and the harness must not weaken maturity requirements simply because a repository does not currently satisfy them.

`.ai/repository.yml` is the committed repository capability profile. Onboarding/discovery is expected to populate it from repository evidence, including languages, frameworks, databases, tests, deployment targets, and infrastructure-as-code such as Terraform, OpenTofu, and Pulumi.

The distinction is intentional:

- `.ai/maturity.yml` = policy: what engineering maturity means.
- `.ai/repository.yml` = evidence-backed state: what this repository currently demonstrates.

Capability findings use `PASS`, `PARTIAL`, `MISSING`, `UNKNOWN`, `EXTERNAL`, or `NOT_APPLICABLE`. Failure to locate evidence is not automatically proof that a capability is missing; use `UNKNOWN` unless absence is established. Externally managed capabilities must identify the external ownership/evidence boundary.

Observability assessment is capability-based rather than dashboard-name-based. A production service must provide failure detection, health signals, operational visibility, and alerting. A CloudWatch/Grafana/Datadog/New Relic dashboard can satisfy operational visibility, but another evidence-backed operator surface may also satisfy it. Discovery should inspect the repository's existing IaC rather than introducing a new IaC tool merely to meet the standard.
