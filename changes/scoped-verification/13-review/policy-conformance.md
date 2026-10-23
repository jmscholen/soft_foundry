# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

From `policies:` in `.ai/repository.yml`, assessed at commit `fb74c5fe` and current on this branch:

- Privacy: status `NOT_APPLICABLE`. Rationale in the profile: library gem, no users' data; outbound calls are provider model listings and the RubyGems version check; the optional session index stays on the machine in `~/.soft-foundry/sessions.jsonl`. No privacy policy document is published.
- Security: status `NOT_APPLICABLE`. Maintainer decision recorded in the profile (2026-09-15, `changes/security-policy-not-applicable`). No `SECURITY.md`.
- Terms: status `NOT_APPLICABLE`. No service; the gem is distributed under its RubyGems listing.

`surfaces.policy` is false. REQ-026 states the same.

## Scope reviewed

The diff from `5abc0e0` to `85edc8e` (library, CLI, tests, control-plane documents, README). Looked for a new collection, recipient, retention change, purpose change, or a change to a published security promise. The new data is repository paths, glob lists, a git tree hash, a recorded test command, and an outcome word, all inside the change record. No new network call, cookie, telemetry event, or log of a person. `session_log` and the session ledger are untouched. The full-suite record stores a command string the operator wrote, which the gate treats as a claim (REQ-008).

## Findings

None.

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. The diff alters nothing Soft Foundry collects, shares, retains, protects, or promises: the profile records no published privacy policy, security policy, or terms, each `NOT_APPLICABLE` with a rationale, and the change adds no collection that would make that rationale false (`.ai/rules/policy-conformance.md`, "What the application has promised" and "Changes that engage this standard").
