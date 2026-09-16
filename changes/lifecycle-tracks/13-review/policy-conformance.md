# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy NOT_APPLICABLE (library gem, no users' data), security NOT_APPLICABLE (maintainer decision 2026-09-15, `changes/security-policy-not-applicable`), terms NOT_APPLICABLE (no service). There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change, so the question is whether that is right: does the change alter anything Soft Foundry itself collects, shares, retains, protects, or promises? Examined: the one new data element written to a committed record (`vetted.by`, a person's name from `--by` or git `user.name`), `reopenings.reason` (free text a person supplies), the journal template's fields, and the new read of git config.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-020 | info | `vetted.by` in `metadata.yml` | A person's name enters the committed repository. Classified: it is the same identity git records as the author of the next commit, supplied by the person or read from their own git config, and it exists so a reader knows who accepted the feature. Nothing is transmitted anywhere. | Rule: classify every new data element |
| REV-021 | info | `.ai/skills/exploration/template/iterations.yml` | The journal's suggested fields (`asked`, `outcome`) invite quoting a person's words into the record. Guidance for governed applications, not data Soft Foundry collects; the standard's classification rule applies to the governed change when it fills the journal. | Rule: data minimisation |

## Policy text changes required
None. This repository publishes no privacy policy, security policy, or terms, so there is no text to change.

## Conformance
N/A, with the statement above of what was examined: the change alters nothing Soft Foundry collects, shares, retains, protects, or promises beyond a name already present in git history, and `surfaces.policy: false` is correct.
