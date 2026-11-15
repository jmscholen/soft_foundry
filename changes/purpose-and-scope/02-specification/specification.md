# Specification

## Intent
State what Soft Foundry is for in the two files a newcomer and an agent read first, and point the attack and review skills at an outside attacker. Requirements are in requirements.yml (REQ-001 to REQ-006).

## Personas and authorization boundaries
- A person adopting Soft Foundry reads `README.md` to learn what it does.
- An agent starting a change reads `.ai/README.md`.
- A fresh attack or review session reads only its skill's `SKILL.md`.
- No authorization boundary changes. The guard and the specification lock work as they do today.

## Functional behavior
- REQ-001: both README files state the purpose near the top.
- REQ-002: the adversarial-testing skill names the attacker, lists what to try, and puts repository-write tampering out of scope.
- REQ-003: the review skill grades against the same threat model.
- REQ-004: the purpose text states the person's role and that the lock is lock and detect.

## Accessibility
REQ-005. The result is Markdown a person reads. Added text keeps heading order, carries no meaning by colour or symbol alone, and contains no hidden characters.

## Data and consistency
No data is stored or changed. The wording in the two README files must agree with each other and with the skills.

## Failure behavior
REQ-006. If an edit breaks the control plane check, `soft-foundry check` fails and the change does not proceed. No code changes.

## Security requirements
REQ-002 and REQ-003 narrow what attack and review report. That is an intentional weakening of a required control and needs the maintainer's recorded approval. What stays in scope is stated in the skill: an outside party using the feature. What leaves scope is stated too: a party with write access to the repository.

Known gap, accepted: a party with write access can still edit `rules` or `risk` in a record's `metadata.yml` (process-speed REV-001 to REV-003). This change does not close it and says so.

## Privacy and security policy conformance
Nothing the policies cover changes. The change collects, shares, retains and promises nothing; the repository profile records the policies as not applicable.

## Performance and resource limits
None. The change should shorten attack and review runs by removing a class of findings; that is not measured here.

## Infrastructure implications
None.

## Observability expectations
None. No runtime behavior changes.

## Acceptance criteria
AC-001 to AC-006 in acceptance-criteria.yml. Must: AC-001, AC-002, AC-003. Should: AC-004, AC-005, AC-006.
