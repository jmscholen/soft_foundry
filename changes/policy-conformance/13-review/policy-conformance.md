# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`, written by this change: privacy NOT_APPLICABLE (library gem, no users' data), security MISSING (no `SECURITY.md` or disclosure route; absence established by searching the repository root, `.github`, and `docs`), terms NOT_APPLICABLE (no service). There is no published document to check the change against, and that is recorded rather than assumed.

## Scope reviewed
`surfaces.policy` is false for this change, so the question is whether that is right: does the change alter anything Soft Foundry itself collects, shares, retains, protects, or promises? Examined: every new file read (`advisory.rb`, `maturity_scan.rb`, `change_record.rb`), every new write (two lines of a freshly created `metadata.yml`, the `policies:` block of `.ai/repository.yml` on a scan), and every outbound path (unchanged: provider model listings and the RubyGems version check).

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-017 | info | `lib/soft_foundry/maturity_scan.rb` `policy_documents` | The scan records file *names* of policy documents into the committed profile. Names only, repository-relative, no contents; nothing about a person. | Rule: data minimisation |
| REV-018 | minor | this repository | The first real finding of the standard is about the repository it runs in: a gem distributed on RubyGems with a public repository publishes no security policy or vulnerability disclosure route. Adding a `SECURITY.md` (how to report, expected response time) is a small follow-up change; until then the profile says MISSING, as the standard intends. | `.ai/rules/policy-conformance.md`, "What the application has promised" |
| REV-019 | info | `.ai/rules/policy-conformance.md` | The standard states that model providers used by the lifecycle receive repository content, not end-user data. That is a statement about governed applications; Soft Foundry's own provider data flows (what a phase runner will send where) are the separate change the intake names as a non-goal, and nothing here changes them. | Rule: recipients |

## Policy text changes required
None. This repository publishes no privacy policy, security policy, or terms, so there is no text to change; REV-018 records the missing security policy as a document to create, not a clause to amend.

## Conformance
N/A, with the statement above of what was examined: the change alters nothing Soft Foundry collects, shares, retains, protects, or promises, and `surfaces.policy: false` is correct. The repository-level gap (REV-018) is an advisory for the maintainer, not a conformance failure of this change.
