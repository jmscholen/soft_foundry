# Access-Control Parity Standard

Verification must say whether the protection around a changed access path was in force when its checks ran. A suite that passes only with a protection switched off for convenience proves nothing about the protected path.

## Applies when

The repository profile (`.ai/repository.yml`) declares `access_control` globs, and a path the change touched matches one of them. A repository that declares no `access_control`, or a change that touches none of those paths, is not subject to this rule.

## What the verification record states

Each check in `06-verification/tests.yml` may carry two optional fields:

| Field | Meaning |
| --- | --- |
| `protection` | `in_force`, `disabled`, or `not_applicable`: the state of the protection the check ran under. |
| `protection_note` | Why. Required whenever `protection` is `disabled`. |

The protection is whatever the access path relies on in the governed application: request forgery protection, an authentication or authorization filter, a rate limit, a permission check. The rule names no framework; the repository's own words go in the note.

## What the gate checks

The `protection stated` check on verification is a structure check. When the profile declares `access_control` and a changed path matches, it requires at least one check stating `protection: in_force`, or every check stating a value with a `protection_note` that explains why none ran with the protection in force. It does not read the tests, and it cannot tell whether a stated claim is true.

## What review checks

Review reads the notes. A check that ran with the protection `disabled` for a path whose behavior depends on it needs a stated reason, and the matching behavior needs a test that runs with the protection in force. A test helper that disables the protection globally is a finding.

## Limits

Presence of the field is not proof of the state. The claim is the verifier's, bound to the commit like the rest of the evidence.
