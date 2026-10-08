# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

`.ai/repository.yml` `policies:` at the committed profile (assessed 2026-09-09, privacy / security / terms):

- privacy: NOT_APPLICABLE. Library gem; no users' data. The rationale names the local session index under `~/.soft-foundry/sessions.jsonl` and says it is not sent anywhere.
- security: NOT_APPLICABLE. Maintainer decision 2026-09-15 in changes/security-policy-not-applicable. No SECURITY.md. Vulnerability reports go through GitHub issues.
- terms: NOT_APPLICABLE. No service; the gem is distributed under its RubyGems listing.

No document has status PASS, so there is no published clause to cite. `surfaces.policy` is false.

## Scope reviewed

What this change collects, shares, retains, or promises. The panel starts coding shells the person already runs, on the person's machine, against the repository. It writes drafts and `ARGUMENT.md` under the change record. It does not add a form, a log of personal data, a recipient, a retention rule, a consent mechanism, or a security promise to a published policy. Session ids in the `panel:` block are ids the runner chose for the local shells, the same kind the single-session runner already records. Staging directories are removed when the run ends. The live evaluation and the attack phase used synthetic text in a scratch repository. REV-SEC-007..009 are integrity failures inside that local record; they do not change what a published policy tells a user.

## Findings

None. No row: nothing the three documents cover changed, and none of those documents is a published PASS policy.

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. Examined the panel command, the handoff `panel:` block, the prompts, the staging directories, and the three `policies:` entries above. The change does not alter what the application collects, shares, retains, protects, or promises.
