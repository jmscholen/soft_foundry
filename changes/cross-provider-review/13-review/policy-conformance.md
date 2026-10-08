# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`.

## Documents checked

`.ai/repository.yml` `policies:`, as recorded by discovery for init-command. No document is published:

- privacy: NOT_APPLICABLE. Library gem with no users' data. The rationale names provider model listings, the RubyGems version check, and the optional local session index, which is not sent anywhere.
- security: NOT_APPLICABLE. Maintainer decision of 2026-09-15 in changes/security-policy-not-applicable: a developer tool, not a service that collects user information. No SECURITY.md.
- terms: NOT_APPLICABLE. No service is offered.

There is no published clause to cite. That absence is the recorded answer, not a document this change contradicts.

## Scope reviewed

`surfaces.policy` is false. Examined the diff and the runtime behavior: the runner reads `resolved_model.provider` and `executed_by.shell` from handoffs already in the repository, chooses among `claude`, `codex`, and `grok` on `PATH`, prints one line, and the gate checks that a review finding above minor has a non-empty `failure:`. Nothing new is collected from a person, stored, or sent. The default shell for review and judgment can now be a different local coding agent than claude; those agents were already reached with `--shell`, and the privacy rationale says the gem transmits nothing about a person. No retention, purpose, consent, or security promise changes.

## Findings

None.

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. The examination above is what supports that: the change does not alter what the application collects, shares, retains, protects, or promises, and the profile records no published privacy policy, security policy, or terms to update. No policy text change is owed, and no human decision is requested.
