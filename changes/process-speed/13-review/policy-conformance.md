# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

`.ai/repository.yml` `policies:` records privacy, security, and terms, each `NOT_APPLICABLE`, with a rationale. There is no published privacy policy, security policy, or terms document (no `PASS` entry, no `SECURITY.md` path recorded as the policy users see). `Advisory.policy_documents` therefore has no document to check a change against. The rationales were read: the gem does not take users' data; the outbound calls it already makes are provider model listings and the RubyGems version check; the optional session index stays on the user's machine.

## Scope reviewed

`surfaces.policy` is false. Examined the diff of `lib/`, `exe/`, `README.md`, and `docs/` since the plan, the specification's privacy section, and the new metadata fields (`rules`, `run_phases`, `tier`, `person_checks`, `blocked_by`, `outside_change`, `docs_only`, and the two `human_decisions` boundaries). Nothing in that diff collects a new field about a person, adds a recipient, changes retention or deletion, changes a purpose, or changes a security commitment a published policy names. There is no such published commitment. The session index and the provider calls are unchanged. The change alters which lifecycle gates refuse a change record. That is the engineering process, not a promise the gem has published to a user.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Policy clause or rule |
| --- | --- | --- | --- | --- | --- |
| REV-016 | minor | `.ai/repository.yml` `policies.security` (outside this change) | The profile's rationale, which this change does not modify, says vulnerability reports go through the public repository's issues and that no security policy is published. Follow-up: a documentation change that adds one, or that reaffirms the NOT_APPLICABLE rationale. | A person shipping the gem can believe this review checked a published security policy. There is no policy text. The profile already says so. | `.ai/rules/policy-conformance.md`, "What the application has promised": a missing published document stays a visible gap of the application. |

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. The examination above is what supports that: the change does not alter what the application collects, shares, retains, protects, or promises in a published privacy policy, security policy, or terms, and the profile records no such document.
