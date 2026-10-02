# Security Review

## Scope reviewed
The new input (command lines), the two subprocess calls, the new route, and what the page renders, against `.ai/rules/security.md` and `03-threat-model/`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-011 | info | `Processes#describe` | Only validated fields leave; arguments after `--` are dropped before any option is read; a child is name and pid. A token after `--` and a prompt were absent from the data in tests and in ATTACK-001. | Secrets in generated artifacts |
| REV-012 | info | `Processes#run_ps`, `#cwd_of` | Argument arrays through `Open3`; the pid is `\d+` from a pattern. No shell. | Injection |
| REV-013 | minor | repository paths | Other repositories' directories are shown, with the home directory shortened. That discloses project names to anything that can read the page: the same local parties as before (ui-server REV-013), who can also run `ps`. It widens what the unauthenticated page reveals from one repository to the user's activity across repositories. | Authorization; data minimisation |
| REV-014 | minor | an option before `--` | A secret passed as a soft-foundry option value that is not one of the reported fields is not shown. A secret passed as `--change` would fail the slug pattern only if it has characters outside it; a token-shaped value could pass and be shown as a change name. Soft Foundry has no option that takes a secret, so this needs a user to mistype one. | Secrets in generated artifacts |
| REV-015 | info | route | Behind the Host check and the cross-site refusal; reads no parameter (ATTACK-002). | CSRF, isolation |

## Conformance
Conforms. REV-013 extends the accepted no-authentication risk and should be weighed with it.
