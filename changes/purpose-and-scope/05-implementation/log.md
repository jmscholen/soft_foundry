# Implementation Log

## Changes made
One commit, `d944d07`, text only:
- `README.md`: a Purpose section after the opening paragraph (REQ-001, REQ-004).
- `.ai/README.md`: the same Purpose section after the opening paragraph, pointing at the two skills; the paragraph that followed gained the heading "Skills and modes" so the heading order stays correct (REQ-001, REQ-005).
- `.ai/skills/adversarial-testing/SKILL.md`: a section "The attacker" naming the outside party, the nine attack classes, and what is out of scope (REQ-002).
- `.ai/skills/review/SKILL.md`: one paragraph on grading against the attack threat model (REQ-003).

No file under `lib/`, `exe/` or `test/` changed (REQ-006). `soft-foundry check` passed before the commit and the pre-commit `ci` passed on it.

The three `.ai/` files and `metadata.yml` were written under the maintainer's local warn override (`.soft-foundry/enforcement.yml`).

## Decisions
See decisions.md.

## Deviations from plan
None. Planning was stepped over by default at low risk; the specification was followed.

## Challenges
- The guard wrote a baseline file under `02-specification/.soft-foundry/` while the session's working directory was that folder. It was removed before the specification seal. Same cause as process-speed's log entry: the hook resolves the repository from the working directory.
