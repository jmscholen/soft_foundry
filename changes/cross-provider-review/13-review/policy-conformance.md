# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

`.ai/repository.yml` `policies:`, assessed at `2026-09-09T15:35:27Z` (commit `cc348f93f3d265af3f92f7fa7d0b09cbbf8a520a`). This change does not add or edit a policy file. None of the three entries is `PASS`, so there is no published document text and no version to cite.

| Document | Status in the profile | What was examined |
| --- | --- | --- |
| privacy | NOT_APPLICABLE | Rationale in the profile: a library gem; no users' data is transmitted. The session ledger stays on the machine. There is no privacy-policy clause. |
| security | NOT_APPLICABLE | Rationale dated 2026-09-15 (change security-policy-not-applicable): no SECURITY.md; reports go through GitHub issues. There is no security-policy clause. |
| terms | NOT_APPLICABLE | Rationale: no service is offered. There is no terms document. |

## Scope reviewed

`surfaces.policy` is false. The diff was checked against the triggers in `.ai/rules/policy-conformance.md`:

- Collects something new: no. Provider names and shell names are already in the change record. The new lines print them on the person's own terminal.
- Adds a recipient: no. Choosing claude, codex, or grok launches a tool the person already runs. No new service receives repository content.
- Changes retention or deletion: no. Handoffs are written as they were. Nothing new is stored about a person.
- Changes purpose: no.
- Changes a security commitment a policy names: no published policy names one. The advisory is an engineering notice, not a promise a customer was shown.
- Changes consent or a rights mechanism: no.

## Findings

None.

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. The diff and the three `policies:` entries were examined. The change does not collect, share, retain, or promise anything the application did not already, and it does not require an edit to a privacy policy, a security policy, or terms, because the profile records that this gem publishes none.
