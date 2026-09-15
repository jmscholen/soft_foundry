# Soft Foundry Rules

Rules define what acceptable engineering work looks like. Skills define who performs a responsibility and how its evidence is produced.

`general.md` and `architecture.md` are baseline implementation rules. Repository discovery must identify applicable language, framework, database, infrastructure, testing, security, and operational rule sets. Applicable rules are loaded by implementation and independently checked by review.

The rule loader must prefer repository-specific standards when they are stricter or more precise, while preserving mandatory Soft Foundry safety and separation-of-duties controls.

`accessibility.md` applies to every change whose `metadata.yml` declares `surfaces.accessibility: true`, and its command-line output rules apply to any CLI regardless. Its findings are reported as go-live advisories by `soft-foundry gate`, `change status`, `ci`, and `change close`; they inform the person shipping rather than block lifecycle advancement.

`policy-conformance.md` applies to every change whose `metadata.yml` declares `surfaces.policy: true`: it checks the change against what the governed application has published in its own privacy policy, security policy, and terms, which discovery records under `policies:` in `.ai/repository.yml`. Its findings are go-live advisories like accessibility's; a policy text change it finds owed is a legal commitment that parks the change at `status: awaiting_human`.

Infrastructure discovery must recognize Infrastructure as Code, including Terraform, OpenTofu, Pulumi, CloudFormation/CDK and other repository-native systems. The presence of IaC makes `infrastructure.md` applicable; tool-specific sections or future rule files may further specialize it.
