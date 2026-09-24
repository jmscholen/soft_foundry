# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change, so the question is whether that is right: does the change alter anything Soft Foundry itself collects, shares, retains, protects, or promises? Examined: the prompt sent to a model provider through the coding shell, `executed_by`'s fields, and the committed `.claude/settings.json`.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-018 | info | `lib/soft_foundry/phase_runner.rb` `prompt` | The prompt names the change, phase, and skill and points at repository files. The session then reads whatever the skill allows and sends it to the shell's provider, which is the same data flow as running the shell by hand; Soft Foundry adds nothing to it. The note from the policy-conformance change stands: Soft Foundry's own provider data flows are a separate, still-open change. | Rule: classify every new data element |
| REV-019 | info | `executed_by` | Timestamps, a shell name, an exit status, a phase id. Nothing about a person. | Rule: data minimisation |

## Policy text changes required
None. This repository publishes no privacy policy, security policy, or terms, so there is no text to change.

## Conformance
N/A, with the statement above of what was examined: the change alters nothing Soft Foundry collects, shares, retains, protects, or promises, and `surfaces.policy: false` is correct.
