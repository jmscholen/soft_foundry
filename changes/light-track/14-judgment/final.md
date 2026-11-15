# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
056098511f3b570ad79648123d9e534cbdbc106d (HEAD of `change/light-track`, `Record light-track review`).

Outside `changes/light-track/` this commit is identical to the implementation commit 4988779 that verification examined (`git diff --stat 4988779 HEAD` outside the record is empty). The commits after it record verification, evaluation and review only.

## Requirements status
The record is under the convergence rules (`rules: 2`), type feature, risk low, on the gated track (the light track does not exist until this change merges). The three must criteria and the removal of required phases on the light track were approved by a person under `human_decisions`. No remediation round has run (limit 2), so the remediation cap is not in play.

| Criterion | Tier | Status | Basis |
| --- | --- | --- | --- |
| AC-001 | must | met | CHECK-002, EVAL-001 (14 of 14, driven through `phase seal`, `gate all` and `change close`, with the gated twin failing), EVAL-010; review reads it as met. |
| AC-002 | must | met | CHECK-002, EVAL-002 (19 of 19: the same named check fails on a light and a gated record in each state; a high-risk light record fails `track permitted`). The third state is tested at the cap and one round above it (DEV-001), which is how the gated track behaves. |
| AC-003 | must | met | CHECK-002, CHECK-008, EVAL-003 (all six spellings fail `outside-change findings` and name the path; an unmodified path passes). |
| AC-004 | should | met as written | CHECK-002, EVAL-004. REQ-006 behind it is fixed for a first round only: REV-001. |
| AC-005 | should | not met in practice | The unit test and CHECK-007 pass in repositories with no `.soft-foundry/`; EVAL-005 fails wherever a phase was sealed or the guard ran: EVL-001, REV-002. |
| AC-006 | should | met | CHECK-010, EVAL-006. |
| AC-007 | should | met in part | `.ai/workflow.yml`, `README.md` and `docs/user/light-track.md` name the track, its required phases, the locks kept and the high-risk exclusion (review read the last two; this session confirmed them). `soft-foundry help` names the track only as a `--track` value: VER-002, EVL-002, REV-004. |
| AC-008 | should | met | CHECK-002, CHECK-007, EVAL-008 (12 of 12), accessibility review. |
| AC-009 | should | met except one assertion | Full suite 951 runs, 0 failures; 35 harness evals pass; the unknown track is refused with the three names. One existing assertion, the list of declared tracks, was changed to include `light` (DEV-003, VER-001). The edit follows from adding a track. |

Every criterion is named by a verification check and an evaluation journey; none is set aside. PC-001 is a person check owed by the maintainer after merge.

Under the convergence rules only an unmet must criterion or a blocking review finding can block. All three must criteria are met and review recorded no blocking finding, so the change is not blocked. The unmet and partly met should criteria and the two major findings are residual risk.

## Verification
Complete at 4988779, current for the judged commit. Nine of eleven checks pass, including the full suite on the evidence commit with provider keys unset (951 runs, 6990 assertions, 0 failures, 0 errors, 0 skips), the change's own tests with a failing-test-first commit (a53ec00), `soft-foundry check` and `soft-foundry ci`. Two checks fail and are acknowledged, both on should criteria: CHECK-009 (one existing assertion changed, AC-009) and CHECK-011 (help text incomplete, AC-007). The manifest's 12 artifacts match.

This session reran `test/light_track_test.rb` on the judged commit as a currency check, not as new evidence: 16 runs, 106 assertions, 0 failures.

## Evaluation
Complete at 119e431, current. Ten journeys through the worktree's CLI in throwaway repositories: eight pass, including the three must journeys and the app-wide smoke. EVAL-005 (AC-005) and EVAL-007 (AC-007) fail, both on should criteria. Accessibility observations pass with one exception: the sizing reason does not name the path that prevented the smaller size. The manifest's 13 artifacts match. Commands not swept are listed in `07-evaluation/results.md`; `soft-foundry ui` was not opened with a light record.

## Attack
Not run. `08-attack/handoff.yml` is pending: at risk low the attack phase is stepped over by default (`default_waivers` in `.ai/workflow.yml`). This is recorded as not run, not as a pass. There is also no threat model for this change, for the same reason. The security review found that no lock reads the track and that the round count errs toward more rounds, not fewer; it is a review, not attack evidence.

## Documentation
The documentation phase (10-user-documentation) and FAQ index (11-faq-index) are optional and did not run. The implementation wrote the user-facing documentation directly: `docs/user/light-track.md`, a row in `docs/user/README.md`, the tracks section of `README.md`, `.ai/README.md` and the tracks comment in `.ai/workflow.yml`. Review read them and found AC-007 met there. Open: the help text (REV-004), a split list in `README.md` (REV-009), and `.ai/schemas.md` not describing the new `sealed` key (REV-006).

## Observability
The observability phase (12-observability) is optional and did not run; `surfaces.observability` is false. REQ-012 is met: `change status` shows the track and says in words why each phase may stay pending, and `--json` carries `track.name` and `skip_reason`. Open: a judged light record reads `phase: learn` until it closes (REV-007).

## Review findings
Review is complete at 2bd8a36, current, run in a fresh session. No blocking finding. Two major and eleven minor findings, all carried in `evidence.yml` under `unresolved_findings`:

- REV-001 (major): a second remediation that was completed in its handoff but never sealed is counted as a round, so a change can park at `awaiting_human` one round early. The error is toward more caution, never past the cap.
- REV-002 (major): the text-only verify size is not reached in any repository holding `.soft-foundry/`, which is every repository where the tool has run. AC-005 is not delivered in practice and the reason printed is misleading.
- REV-003 to REV-009, REV-012, REV-013 (minor) and REV-010, REV-011 (minor, outside this change, carried as follow-ups by the gate).

REV-005 asked that this judgment record attack as not run; it does, above and in `evidence.yml`.

## Residual risk
Listed in `residual-risk.md` (R-1 to R-8). In short: the two should-tier fixes this change set out to make (REQ-006, REQ-007) are only partly delivered; there is no attack evidence or threat model; the evidence phases ran on the implementing provider; the installed gem does not yet have the track; and the guard hook misreported again during this session.

What the maintainer decides when accepting the result:
1. Whether REV-001 and REV-002 are accepted as follow-ups for the next change or remediated here. Neither weakens a lock. REV-002 means the time saving this change was meant to bring to text-only changes is not yet real.
2. Confirmation of the two `human_decisions` entries, which the agent session typed under the local override (R-5).
3. PC-001 after merge, with the gem rebuilt and installed locally (REV-012).
