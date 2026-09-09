# `.ai/` Control Plane

`.ai/` defines HOW engineering work is performed. It contains lifecycle orchestration, skill contracts, policies, model profiles, runtime configuration, and deterministic checks. It should not become a duplicate home for product/domain documentation; canonical human/agent product documentation belongs under `docs/`.

A skill is a declarative agent definition. The harness loads its instructions, model profile, permissions, required inputs, template-derived working artifacts, tools, and completion gate into an isolated execution context.

The host may operate in either mode:

- **Enforced mode:** a harness technically constrains filesystem, commands, credentials, context, and model selection.
- **Compatibility mode:** a coding platform follows the same contracts from repository instructions when hard sandboxing is unavailable.

Canonical source templates under `.ai/skills/*/template/` are immutable workflow definitions. Copies under `changes/<change>/` are mutable execution records.
