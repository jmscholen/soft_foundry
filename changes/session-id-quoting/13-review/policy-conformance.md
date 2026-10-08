# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

`.ai/repository.yml` `policies:`, as assessed at `2026-09-09T15:35:27Z` (commit `cc348f93f3d265af3f92f7fa7d0b09cbbf8a520a`). No policy file was added or edited by this change.

| Document | Status in the profile | What was examined |
| --- | --- | --- |
| privacy | NOT_APPLICABLE | Rationale in the profile: a library gem, no users' data transmitted; the session ledger stays on the machine in `~/.soft-foundry/sessions.jsonl`. There is no privacy policy text and no version to cite. |
| security | NOT_APPLICABLE | Rationale dated 2026-09-15 (change security-policy-not-applicable): no SECURITY.md; vulnerability reports go through GitHub issues. There is no security-policy clause to cite. |
| terms | NOT_APPLICABLE | Rationale: no service is offered. There is no terms document to cite. |

## Scope reviewed

`surfaces.policy` is false. The diff was checked for each trigger in `.ai/rules/policy-conformance.md`:

- Collects something new: no. `record` still writes the same fields. Lookup returns a subset of lines already on disk.
- Adds a recipient: no. Nothing is sent off the machine. Quoting changes a string printed locally.
- Changes retention or deletion: no. Rejected lines stay in the ledger. Lookup does not delete them. Nothing new is stored.
- Changes purpose: no. The ledger is still a local index of the person's own sessions.
- Changes a security commitment a policy names: no published security policy names session handling, encryption, or disclosure. The code's paste check is tighter. That is an engineering control under `security.md`, not a change to a promise a person was shown.
- Changes consent or a rights mechanism: no.

## Findings

None.

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. The diff and the three `policies:` entries were examined. The change does not collect, share, or retain anything new, and it does not contradict or require an edit to a privacy policy, a security policy, or terms, because the profile records that this gem publishes none. The stronger local check on ledger lines is not a published security promise.
