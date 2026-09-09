# Soft Foundry

Soft Foundry is a repository-native operating system for autonomous software engineering. It defines how an LLM coding platform discovers a repository, executes a change through isolated skills, verifies intent, attacks assumptions, generates user documentation, and records evidence for final judgment.

## Core principles

- Model and vendor neutral. The repository owns the workflow; providers are replaceable compute.
- Every phase starts from a canonical skill template.
- Skills follow least privilege and separation of duties.
- No skill may both implement a change and control the evidence used to judge it.
- Evidence is bound to a Git commit and becomes stale when implementation changes.
- User documentation is generated from successful behavioral evaluation, not merely from code or plans.
- Attack testing attempts to violate intended behavior through real application surfaces.
- Application-specific infrastructure and observability may live with the application when lifecycle and ownership are coupled.

## Canonical lifecycle

INTAKE -> DISCOVER -> SPECIFY -> THREAT MODEL -> PLAN -> IMPLEMENT -> VERIFY -> EVALUATE -> ATTACK -> REMEDIATE (loop) -> DOCUMENT -> INDEX -> OBSERVE -> REVIEW -> JUDGE -> LEARN

See `AGENTS.md` and `.ai/workflow.yml` for the execution contract.
