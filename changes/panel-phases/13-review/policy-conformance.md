# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`.

## Documents checked

`.ai/repository.yml` `policies:`, assessed with the repository profile (no later change has published a policy document):

| Document | Status | What was read |
| --- | --- | --- |
| privacy | NOT_APPLICABLE | Rationale in `.ai/repository.yml`: library gem, no users' data; outbound calls are provider model listings and the RubyGems version check; the optional session index stays on the machine. |
| security | NOT_APPLICABLE | Maintainer decision recorded there (2026-09-15, changes/security-policy-not-applicable). No `SECURITY.md`. |
| terms | NOT_APPLICABLE | No service; the gem is the RubyGems listing. |

There is no published clause to cite. That absence is the recorded profile, not a document this change creates.

## Scope reviewed

`surfaces.policy` is false. Checked whether that is right for this change: what a panel newly stores or sends. Examined `Panel#block` (member name, shell, provider, session id, rounds, outcome, notes, failures, dropped), the prompts, `spawn_panel` (local child processes, no new network client), and the draft files copied into the change record. Session ids were already written to `executed_by` by a single-session `phase run`. Drafts are the phase record the person chooses to commit. No new recipient, no end-user data, no change to retention of the session ledger, no change to a security or privacy promise in a published document. The guard override in REV-SEC-014 is a local control bypass, not a change to a published security policy.

## Findings

No findings.

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false, and the examination above is what supports that: the change does not alter what the application collects, shares, retains, protects, or promises in a published privacy policy, security policy, or terms. Nothing is owed under `human_decisions`.
