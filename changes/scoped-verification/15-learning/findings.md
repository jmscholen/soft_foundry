# Learning

## What this change taught us
- **A gate that reads state its author controls can be steered by that author.** The staleness check measures "code changed since the evidence" on a base chosen by `metadata.yml` `git.branch`. Three fix attempts (REV-001, ATTACK-F-006, ATTACK-F-007) each closed one way to move that base and left another: repointing after the evidence (fixed by a `branch_edit` stale cause), a ref created at the evidence commit (fixed by `tip_for` taking the evidence sha), and a ref named before it exists and created later at the phases-complete commit (ATTACK-019/020, accepted residual). Ancestry cannot separate the last case from a legitimate stacked branch (ATTACK-021). What is missing is a recorded fact: whether the named ref resolved at the evidence commit. The lesson is to record the resolved fact when a declaration selects the measurement, not only the declaration string.
- **A fix to a shared measurement rule can break a neighbouring feature.** The first REV-001 attempt (measure at HEAD for every branch behind HEAD) failed 3 tests in `test/stacked_branch_test.rb`. The rule was replaced, which is why the stacked fixtures are a regression guard worth keeping.
- **Path listings must not collapse renames.** `git diff --name-only` reports only a rename's destination, so moving access-control code out of a path left its record current and hid the sizing signal (ATTACK-013). Fixed with `--no-renames` and a rename test.
- **Identifiers resolved through the filesystem must be compared exactly.** On a case-insensitive filesystem a citation of `ALPHA` resolved to `alpha` (ATTACK-016). Fixed by requiring the resolved directory name to equal the slug.
- **A locked artifact that cannot be parsed hides evidence from tooling.** `02-specification/requirements.yml` has an unquoted `fail closed:` in REQ-016, so `YAML.safe_load` stops at line 81 and the go-live accessibility advisory (which swallows the error) sees no requirements. Review, evaluation and the suite read it as text, so nothing caught it until judgment. Editing it after lock is a recorded requirement change, so it is owed as a follow-up.
- **Malformed metadata should fail with a gate line, not a Ruby error.** A scalar `git:` made the gate exit 1 with `String does not have #dig method` (ATTACK-018, REV-004). It fails closed, so this is a message-quality defect only.
- **Maintainer decisions that supersede locked text belong in the record.** REV-002 superseded REQ-009 for claimed paths without editing the locked spec; the remediation summary and direction file carried the supersession, and the policy and README were corrected afterwards. This worked and is worth repeating.

## Reviewer/evaluator/attack findings worth generalizing
- REV-001 / ATTACK-F-007 / ATTACK-019 / ATTACK-020 (blocking at review, accepted at judgment): an author-selected measure base.
- ATTACK-013: rename collapse in a changed-path listing (fixed).
- ATTACK-014 / ATTACK-F-006: editing a measure-selecting declaration after the evidence (fixed as a stale cause).
- ATTACK-016: case-folded identifier resolution (fixed).
- REV-003 / ATTACK-015: an active record scoped `**` claims every path (accepted; the README states it).
- REV-004 / ATTACK-018: non-mapping metadata value crashes the loader (accepted).
- REC-001 (judgment): locked specification file does not parse as YAML.
- VER-001: one `ProcessesTest` failure under load, passed alone and on rerun of the same tree; cause not shown. Not generalized beyond noting that a flaky live-process test costs a rerun and a recorded explanation.

## Proposed deterministic checks
1. A `soft-foundry check` or gate-time check that every phase artifact YAML file in a change record (requirements, tests, handoffs) parses with `YAML.safe_load`, so an unparseable locked specification is refused at lock rather than discovered at judgment (REC-001).
2. A gate rule that records, in the evidence commit's handoff, whether the `git.branch` named in `metadata.yml` resolved at that commit, and measures at the checked-out HEAD if a ref that did not resolve then resolves now (the owed REV-001 mitigation). This is a product change to `lib/`, so it needs its own change, not a rule edit.
3. Make the go-live advisory report a parse error instead of swallowing it, so a file it cannot read is visible.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`. Harness evals were not read (denied to this skill); the proposals are written from the change record only and a maintainer should check them against existing cases before adopting.
