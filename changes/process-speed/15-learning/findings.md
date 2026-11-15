# Learning

## What this change taught us
- The attack phase had no named attacker. Its skill says "try to make the implementation violate its intent". On a change whose intent is a process rule, that led the attack session to edit the change record (delete `rules`, lower `risk`, repoint `git.branch`). Review graded the result blocking (REV-001) and major (REV-002, REV-003). The maintainer decided on 2026-11-14 that this is not the threat model: attack and review look at an outside party using the feature. Someone with write access to the repository editing the record is out of scope for both phases.
- The maintainer restated the repository's purpose in the same session: an autonomous factory in which agents build application features under gated phases, with the specification locked once a person approves it. The lock is "lock and detect": the gate fails when the locked files change. No phase hunts for ways around the lock.
- The tool's own changes ran the full lifecycle at high risk. Evidence phases and their reruns took most of a day on a change whose code was finished and passing in the first hours. The maintainer chose a light track for the tool's own changes: specification, implementation, the test suite and one review.
- A human decision that accepts findings as residual risk let judgment proceed without a remediation round. Judgment returned APPROVED_WITH_RESIDUAL_RISK in one run.
- A code fix after review makes evaluation and attack stale, and high risk waives neither. Fixing two small defects (REV-004, REV-005) would have cost a full round, so they are carried to the next change.
- This record was created before `change new` wrote `rules: 2`, so the rules it introduces never applied to it. The first record to run under them will be the next one.

## Reviewer/evaluator/attack findings worth generalizing
- REV-004: paths in an outside-change finding are compared as written. `./lib/app.rb` and `lib/app.rb` are different strings, so a finding about modified code can be marked outside the change by accident. Normalize paths before comparing.
- REV-005: the round count includes remediations that were reopened before they completed, and the refusal message calls them sealed. A message must describe what was counted.
- REV-013: `Git#count_subject` returns 0 when git fails, so a failure reads as "no rounds". A count that guards a limit should fail loudly.
- IMPL-002 and FIND-ATT-026: the guard does not recognise a shell redirection as a write, and it resolves the repository from the working directory. Both are guard defects, not defects of this change.
- VER-003: only the remediation-cap refusal was checked with colour off and non-ASCII characters removed. The other new messages were not.

## Proposed deterministic checks
- Normalize the paths of an outside-change finding and refuse absolute paths and globs (REV-004).
- Treat a git failure in a round count as an error (REV-013).
- A suite result keyed by a hash of the code paths, so a phase that changes no code reuses the recorded run. The suite ran five times on identical code during this change.

## Proposed rule changes
See proposed-rules.md.

## Proposed harness evals
See proposed-evals.md.

## Follow-ups carried out of this change
1. Purpose and scope: state the repository's purpose in `README.md` and `.ai/README.md`; name the attacker in the adversarial-testing and review skills; add a light track for the tool's own changes.
2. Application-type paths (web app, API service, CLI or library), each setting what evaluation and attack look for. The check catalog discussed during intake belongs here.
3. REV-004 and REV-005 fixes, on the light track.
4. Guard: shell redirections, heredoc and tilde parsing, repository root taken from the working directory (IMPL-002, FIND-ATT-026). REV-001, REV-002 and REV-003 are recorded against this follow-up as residual risk; whether to bind `rules` and `risk` to the intake commit is decided there.
5. `phase run --parallel`: the second seal is refused by the pre-commit `ci` while the first is uncommitted.
6. When Soft Foundry develops itself, seals and the runner should use the branch's code, not the installed gem.
7. Run the test suite in parallel.
8. Closure of the tabled records (readme-workflow-visuals, release-0-23-0).
9. REV-016: the published security policy question, already decided as not applicable by the maintainer.
