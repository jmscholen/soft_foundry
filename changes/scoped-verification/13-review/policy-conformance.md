# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

`.ai/repository.yml` `policies:`, as named in `01-discovery/repository-context.md` ("Published policies"):

- privacy: `NOT_APPLICABLE`. Library gem; no users' data. Outbound calls are provider model listings and the RubyGems version check. The optional session hook writes a local index under `~/.soft-foundry/` and does not send it.
- security: `NOT_APPLICABLE`. Maintainer decision 2026-09-15 (`changes/security-policy-not-applicable`). No SECURITY.md. Vulnerability reports go through the public repository's issues.
- terms: `NOT_APPLICABLE`. No service. The gem is distributed under its RubyGems listing.

No published privacy policy, security policy, or terms document exists to cite a clause from. That absence is the recorded rationale for a library with no users' data, which `.ai/rules/policy-conformance.md` allows as `NOT_APPLICABLE`.

## Scope reviewed

`surfaces.policy` is false. REQ-026 states the change does not alter what Soft Foundry collects, shares, retains, protects, or promises. Examined the diff and the new behavior: scope, shared core, and access-control globs are path lists in the repository; the full-suite record stores a tree hash, a command, and an outcome; sizing reads a policy file of size names. No new data about a person, no new recipient, no retention or deletion change, no consent or rights mechanism, and no change to a security commitment a policy names. The session index and the provider calls predate this change and are already described in the privacy rationale.

## Findings

No findings.

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. The three documents under `policies:` are `NOT_APPLICABLE`, and the change adds no collection, recipient, retention rule, or promise those documents would have to cover.
