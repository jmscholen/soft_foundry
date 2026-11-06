# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
`.ai/repository.yml` `policies:` at HEAD `5b2a028`:

- `privacy`: `NOT_APPLICABLE`. Rationale recorded by discovery: a library gem with no users' data; the only outbound calls are provider model listings and the RubyGems version check; the optional session hook keeps a local index on the user's own machine, readable only by that user and never sent anywhere, documented in README.md.
- `security`: `NOT_APPLICABLE`. Maintainer decision 2026-09-15 (`changes/security-policy-not-applicable`): a developer tool, no published security policy owed; vulnerability reports go through the public GitHub repository's issues.
- `terms`: `NOT_APPLICABLE`. No service is offered; the gem is distributed under its RubyGems listing.

The application publishes no privacy policy, security policy or terms, and the profile records why for each. No document exists to check a clause against.

## Scope reviewed
`surfaces.policy` is false. What was examined to confirm that nothing the standard covers changes:

- The diff from `main` outside `changes/`: three documentation files, one protected-policy header comment, one hook settings file. No code, so no new collection, recipient, retention, purpose, consent mechanism or security commitment.
- The hook entries run `soft-foundry guard` locally; the guard writes only to the machine-local, gitignored `.soft-foundry/` directory (`guard.log`, `guard-baseline.yml`) and sends nothing anywhere. The log records tool name, skill, repository-relative paths and the reason, as before this change. The baseline holds copies of the guard's own configuration files, as before this change (0.21.0). Neither is new here; this change only documents them.
- The documentation describes these local files and says where the log is; nothing promised to a user changes.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Policy clause or rule |
| --- | --- | --- | --- | --- | --- |

No finding. There is no data element to classify and no clause that could be contradicted.

## Policy text changes required
None.

## Conformance
N/A. `surfaces.policy` is false, and the examination above found that the change alters nothing the application collects, shares, retains, protects or promises: it documents behaviour that already exists, and the only files the documented behaviour writes are machine-local and gitignored. The three `NOT_APPLICABLE` entries in the repository profile are established with rationales, so the absence of published documents is not itself a go-live gap for this repository.
