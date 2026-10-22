# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`.

## Documents checked
`.ai/repository.yml` `policies:` records `privacy` as NOT_APPLICABLE (library gem with no users' data; rationale cites README.md network calls and the optional local session index). I read that record at HEAD. The application publishes no separate security policy or terms recorded there as engaged by this change.

## Scope reviewed
`surfaces.policy: false`. I examined the diff for new collection, recipients, retention and purposes: the change adds a local guard log and baseline under `.soft-foundry/` (machine-local, gitignored, containing file contents of the guard's own configuration only), a live eval that runs a provider session on repository content and synthetic planted defects, and `Text.read_text`. No end-user data is collected or sent, no new recipient is added, retention is unchanged, and no consent mechanism changes. The guard's `block` default changes a security behaviour the README describes (see REV-001) but does not contradict a published privacy or security clause. The README is the only published statement, and it is amended by that finding rather than contradicted.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Policy clause or rule |
| --- | --- | --- | --- | --- | --- |
| REV-010 | minor | `README.md` guard paragraph | The README's description of what the guard enforces predates block mode and the post-call restore (see REV-001); a published security promise is therefore understated, not overstated. | None that harms a user; a reader may expect weaker protection than ships. | policy-conformance.md "Nothing the change ships contradicts a published clause" |

## Policy text changes required
None.

## Conformance
N/A is not claimed; conforms. The change alters nothing the application collects, shares, retains, protects for a person, or promises in a privacy policy, security policy, or terms.
