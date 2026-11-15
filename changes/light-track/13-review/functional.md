# Functional Review

Commit reviewed: 2bd8a36ebac217d90174639deddb292765665b07. The code tree is the one verified at 4988779 and evaluated at 119e431; the commits between record evidence only.

## Scope reviewed
- The change's diff from e3004a2 (the commit before the record was scaffolded) to HEAD: `.ai/workflow.yml`, `lib/soft_foundry/change_record.rb`, `cli.rb`, `gate.rb`, `phase_reopen.rb`, `process_rules.rb`, `sizing.rb`, `test/light_track_test.rb`, `test/lifecycle_tracks_test.rb`, the two skill wording edits, `README.md`, `docs/user/light-track.md`, `docs/user/README.md`.
- Code the change relies on but did not modify: `ChangeRecord#skippable?`, `#recorded_commit`, `#reached_lifecycle_end?`, `PhaseSeal#advance!`, `Git#diff_paths` and `#status_entries`, `Check#check_tracks`, `Scope#change_base`.
- Verification (CHECK-001 to CHECK-011) and evaluation (EVAL-001 to EVAL-010) evidence. Every artifact matches the SHA-256 in its manifest (12 of 12, 13 of 13).
- Run by this review: `test/light_track_test.rb` (16 runs, 0 failures), `soft-foundry check` (pass), and `evidence/review-probe.rb` (output in `evidence/review-probe.txt`).

## Criteria
| Criterion | Tier | Review's reading |
| --- | --- | --- |
| AC-001 | must | Met. The track is one `tracks:` entry; `skippable?` already feeds the gate's predecessor check, the seal, the runner and `change close`. EVAL-001 drives it through the CLI, with the gated twin failing. |
| AC-002 | must | Met. No lock reads the track; EVAL-002 shows the same named check failing on both tracks, and `track permitted` failing at high risk. |
| AC-003 | must | Met. All six spellings fail the check and the path is named; an unmodified path passes. |
| AC-004 | should | Met as written (a remediation reopened while `in_progress` is not counted). The implementation's wider aim, that an unsealed remediation is not a round, does not hold for a second round: REV-001. |
| AC-005 | should | Not met in a repository that holds any git-ignored file: REV-002. |
| AC-006 | should | Met. Both skill texts say what the criterion asks. |
| AC-007 | should | Met in part. `.ai/workflow.yml`, `README.md` and `docs/user/light-track.md` each name the track, its required phases, the locks kept and the high-risk exclusion (README.md and the guide were read here; verification and evaluation could not read them). `soft-foundry help` does not: REV-004. |
| AC-008 | should | Met. |
| AC-009 | should | Met except one existing assertion, the list of declared tracks (implementation DEV-003, VER-001). The edit follows from adding a track and weakens nothing. |

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | `lib/soft_foundry/phase_reopen.rb` `previous`; `lib/soft_foundry/process_rules.rb` `reopened_rounds` | `sealed` is taken from `recorded_commit`, which returns the newest `Record <slug> remediate` commit. Once one round has been sealed, that commit answers for every later round, so a later remediation that was completed in its handoff but never sealed is recorded `sealed: true` and counted. | Round one is sealed and reopened. Round two's handoff says complete, its seal is refused (or `phase run` finds it stale) and it is reopened. `evidence/review-probe.txt` PROBE-1: one `Record` commit, `reopened_rounds` 2, `another_round_allowed?` false. The change is parked `awaiting_human` one round early with a message saying it has run 2 rounds. PROBE-2 shows the first-round case is fixed. | REQ-006; process-speed REV-005 |
| REV-002 | major | `lib/soft_foundry/sizing.rb` `documentation_only` (cause in `lib/soft_foundry/git.rb` `status_entries`, not modified) | The paths sizing reads include git-ignored files (`git status --ignored=matching`). `.soft-foundry/` is written by `phase seal` and by the guard, so it is present wherever the tool has been used, and it is not text. | A change edits only README.md, a page under docs/, its record and a skill's SKILL.md, in a repository where a phase was sealed. `change size --phase verify` reports `full_at_verify` with the reason "no scope declared" and the full suite runs (EVAL-005; the same transcript reports the smaller size once `.soft-foundry/` is deleted). The reason does not name the path that prevented the smaller size. | REQ-007, AC-005 |
| REV-003 | minor | `lib/soft_foundry/process_rules.rb` `normalize_path` | A file whose name holds `[`, `]`, `{`, `}`, `?` or `*` cannot be named in an outside-change finding: `app/[id]/page.tsx` and `src/routes/[slug].svelte` return nil (PROBE-3). REQ-005 asks for globs to be refused, so the code does what was specified. In an application with bracketed route files the reviewer has to name the parent directory. | | REQ-005 |
| REV-004 | minor | `lib/soft_foundry/cli.rb` help text | `soft-foundry help` names the light track only as a value of `--track`. Confirms VER-002 and EVL-002. | | REQ-009, AC-007 |
| REV-005 | minor | `.ai/skills/final-judgment/SKILL.md` and its `evidence.yml` template (not modified) | The specification, README.md and the user guide say judgment records attack as not run, not as a pass. Nothing in the judgment skill or its template says so, and no check reads the `08-attack` row. The statement rests on the judging session noticing a pending handoff. | | specification.md, Security requirements |
| REV-006 | minor | `.ai/schemas.md` (not modified) | The specification says no new record fields. A reopen entry now carries `previous.remediate.sealed`, and schemas.md still defines a round as a reset of "a complete remediation". decisions.md records the key; the schema reference does not. | | specification.md, Data and consistency |
| REV-007 | minor | `.ai/workflow.yml` `transitions.judge.next`; `PhaseSeal#advance!` | After `phase seal judge` on a light record `current_phase` is `learn`, a phase the track makes optional, because the loop transition is taken before the skip rule. `change status` reads `phase: learn` until the record closes. Confirms EVL-003. | | REQ-012 |
| REV-008 | minor | `lib/soft_foundry/process_rules.rb` `normalize_path` | `LIB/app.rb` and `lib\app.rb` are returned unchanged and pass as outside a change that modified `lib/app.rb` (PROBE-3). AC-003 does not list them. Confirms VER-004 and EVL-004. | | REQ-005 |

## Conformance
Conforms for the three must criteria. Two should criteria are not fully delivered (AC-005 by REV-002, AC-007 by REV-004), AC-009 is met except the one assertion, and REQ-006 is fixed for a first round only (REV-001). No finding is blocking.
