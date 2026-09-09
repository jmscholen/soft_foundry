# `.ai/` Control Plane

`.ai/` defines HOW engineering work is performed. It contains lifecycle orchestration, skill contracts, policies, model profiles, maturity policy, repository capability assessment, runtime configuration, and deterministic checks. It should not become a duplicate home for product/domain documentation; canonical human/agent product documentation belongs under `docs/`.

A skill is a declarative agent definition. The harness loads its instructions, model profile, permissions, required inputs, template-derived working artifacts, tools, and completion gate into an isolated execution context.

The host may operate in either mode:

- **Enforced mode:** a harness technically constrains filesystem, commands, credentials, context, and model selection.
- **Compatibility mode:** a coding platform follows the same contracts from repository instructions when hard sandboxing is unavailable.

Canonical source templates under `.ai/skills/*/template/` are immutable workflow definitions. Copies under `changes/<change>/` are mutable execution records.

## Repository maturity and gap analysis

`.ai/maturity.yml` is the canonical, machine-readable Soft Foundry maturity model. It defines levels, required capabilities, allowed assessment states, observability expectations, and scoring semantics. Agents and the harness must not weaken maturity requirements simply because a repository does not currently satisfy them.

`.ai/repository.yml` is the committed repository capability profile. Onboarding/discovery is expected to populate it from repository evidence, including languages, frameworks, databases, tests, deployment targets, and infrastructure-as-code such as Terraform, OpenTofu, and Pulumi.

The distinction is intentional:

- `.ai/maturity.yml` = policy: what engineering maturity means.
- `.ai/repository.yml` = evidence-backed state: what this repository currently demonstrates.

Capability findings use `PASS`, `PARTIAL`, `MISSING`, `UNKNOWN`, `EXTERNAL`, or `NOT_APPLICABLE`. Failure to locate evidence is not automatically proof that a capability is missing; use `UNKNOWN` unless absence is established. Externally managed capabilities must identify the external ownership/evidence boundary.

Observability assessment is capability-based rather than dashboard-name-based. A production service must provide failure detection, health signals, operational visibility, and alerting. A CloudWatch/Grafana/Datadog/New Relic dashboard can satisfy operational visibility, but another evidence-backed operator surface may also satisfy it. Discovery should inspect the repository's existing IaC rather than introducing a new IaC tool merely to meet the standard.
