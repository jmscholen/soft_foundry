# Soft Foundry Rules

Rules define what acceptable engineering work looks like. Skills define who performs a responsibility and how its evidence is produced.

`general.md` and `architecture.md` are baseline implementation rules. Repository discovery must identify applicable language, framework, database, infrastructure, testing, security, and operational rule sets. Applicable rules are loaded by implementation and independently checked by review.

The rule loader must prefer repository-specific standards when they are stricter or more precise, while preserving mandatory Soft Foundry safety and separation-of-duties controls.

Infrastructure discovery must recognize Infrastructure as Code, including Terraform, OpenTofu, Pulumi, CloudFormation/CDK and other repository-native systems. The presence of IaC makes `infrastructure.md` applicable; tool-specific sections or future rule files may further specialize it.
