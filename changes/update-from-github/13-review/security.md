# Security Review

## Scope reviewed
Downloading and installing code, against `.ai/rules/security.md` and `03-threat-model/`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-008 | info | version agreement | Requested, tagged, and file-named versions must agree before `gem install` runs; the real refusal was observed. | Dependency integrity |
| REV-009 | minor | integrity | Beyond TLS there is no checksum or signature. Anyone who can create a release on the repository can ship code the updater installs; that is the repository's own trust boundary, and the workflow being the only release path (tag, version check, tests) is what keeps it honest. A checksum in the release body is a follow-up. | Supply chain |
| REV-010 | minor | token | Sent to github.com hosts only; dropped on redirects elsewhere; untested (REV-003). | Secrets |
| REV-011 | info | subprocesses | Argument lists only: `tar`, `gem build`, `gem install --local`; no shell. | Injection |
| REV-012 | info | temporary files | Created with `Dir.mktmpdir` and removed. | File handling |
| REV-013 | minor | workflow | `contents: write` with the default token, on tag pushes only. Anyone with push access to tags can publish; branch and tag protection are the repository's to set. | Infrastructure |

## Conformance
Conforms, with REV-009 and REV-013 as the things to know.
