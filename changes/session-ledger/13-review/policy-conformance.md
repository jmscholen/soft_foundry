# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

No published privacy policy, security policy, or terms document is recorded. `.ai/repository.yml` `policies:`, as it stands on this branch:

- `privacy`: status NOT_APPLICABLE. Profile `assessed_at` 2026-09-09. The rationale was updated by this change's discovery. It says the gem has no service users and no person is transmitted, and that once `soft-foundry hooks install --sessions` is run the user's own machine keeps `~/.soft-foundry/sessions.jsonl` (folders, branches, and masked prompt excerpts), readable only by that user. It points at README.md.
- `security`: status NOT_APPLICABLE. Rationale cites the maintainer decision of 2026-09-15 (`changes/security-policy-not-applicable`): a developer tool, not a service; no SECURITY.md; reports go through GitHub issues.
- `terms`: status NOT_APPLICABLE. No service; the gem is the RubyGems listing.

There is no path or URL to open for any of the three. `surfaces.policy` is false, which matches the schema: the flag means a published policy, security policy, or terms text would change. None exists.

## Scope reviewed

What the change actually retains, because that is the question the standard asks before anyone may write a conformance of not applicable. With the hook installed, `SessionLedger#record` writes, on the user's machine only: agent, session ID, folder, repository root, branch, change slug, phase, transcript path when the agent sent one, first and last seen times, and the first and latest prompt cut to 140 characters with `ContentScan::SECRETS` shapes replaced. Nothing in this change opens a network connection. The UI shows those fields on loopback to the same user. Uninstall keeps the file until the person deletes it. README states the same list, the path, the mask, and that nothing is sent.

That is new local collection and retention of content a person writes. It does not alter a published clause, because there is no published clause. The specification's privacy section, discovery's "Published policies" section, and the repository rationale agree on that, and the rationale matches the code.

The find-session skill tells an agent how to search the agents' own transcript files when the ledger misses. Those files already exist; this change does not add a recipient or a new copy of them.

## Findings

None.

## Policy text changes required

None.

## Conformance

Conforms. A conformance of not applicable is the wrong word: the change does alter what is collected and retained on the user's disk. It does not contradict a published privacy policy, security policy, or terms document, and the in-repository rationale and README now say what is kept. Publishing a new policy would be a legal commitment the maintainer has already recorded as not owed (security, 2026-09-15; privacy and terms, NOT_APPLICABLE with rationale). No text change is owed, so nothing is parked for `human_decisions`.
