# Final Judgment

## Outcome
**APPROVED_WITH_RESIDUAL_RISK**

## Commit judged
`c34f65cd6dc86c6b523629705884efbfa6450336` (branch `change/session-id-quoting`, HEAD when this judgment was written).

Application and test code are the implementation commit `6f753070e06ed9eb74b9744541b409429f81afa8`. `git diff --name-only 6f75307 HEAD -- lib exe test infra .github` is empty, and the worktree has no uncommitted changes on those paths. `d08f74e` recorded the implementation, verification, evaluation, and attack files. `c34f65c` recorded the review. Neither commit changes `lib/`, `exe/`, `test/`, or `infra/`. See `evidence.yml`.

This judgment also called `SessionLedger.trusted?` and `SessionLedger.resume_command` on this worktree, and read `entries`, `CLI#sessions`, `CLI#resume`, `PhaseRunner#recorded_session`, `Snapshot#recorded_sessions`, and `el` in `app.js`. No application file was edited. The full suite and the attack shell were not re-run.

## Requirements status
The specification phase was skipped. The acceptance bar is REQ-SQ-001, REQ-SQ-002, and REQ-SQ-003 in `00-intake/request.md`, which `metadata.yml` records as the stand-in. All three hold.

- REQ-SQ-001. `entries` is the only ledger read lookup uses. `search`, `latest`, `sessions` (text and `--json`), `resume`, `Snapshot#recorded_sessions`, and `PhaseRunner#recorded_session` all go through it. A line is returned only when `session_id` is a String matching `SessionLedger::ID`, `agent` is `claude`, `codex`, or `grok`, and `cwd` is a String. Lookup does not rewrite the file. The new test asserts the planted lines stay on disk.
- REQ-SQ-002. `resume_command` passes the session id through `Shellwords.escape` as well as the folder. Callers in the CLI and the snapshot use that method. The page assigns the string with `textContent`.
- REQ-SQ-003. `SoftFoundry::VERSION` is `0.18.1`.

No acceptance criterion is left open. `undischarged` is empty.

## Verification
**Disposition: passed, current for the judged code.** Bound to `6f753070e06ed9eb74b9744541b409429f81afa8`. No library, executable, or test file has changed since that commit. The evidence hashes in `06-verification/evidence/manifest.yml` match the logs.

CHECK-001: 468 runs, 3129 assertions, 0 failures, provider keys unset. CHECK-002: at RED commit `af7da27687406f0fdb67df115c3204d2ebc70770`, 2 runs, 2 failures, 0 errors. That commit is an ancestor of the verified commit, the test file exists there, and `lib/soft_foundry/session_ledger.rb` changed after it. CHECK-003, CHECK-004, and CHECK-005 passed (`soft-foundry check`, `ruby -wc`, `soft-foundry scan` with 0 errors).

`05-implementation/deviations.md` records that the RED quoting expectation was a double-quoted Ruby string. Review evaluated it as `x;\ touch\ PWNED`, which is neither the old unquoted id nor `Shellwords.escape`. The replacement, a single-quoted `x\;\ touch\ PWNED`, is the string this worktree builds. The unquoted command does not end with that string, so the corrected test would still have failed before the fix. Review approved the correction. This judgment agrees. It is not a weakened requirement.

## Evaluation
**Disposition: passed.** Bound to `6f75307`. The transcript hash matches the manifest.

EVAL-001: the CLI lists one grok session, status word `resumable`, and a resume command whose id is the plain UUID `0199d1a2-5b6c-7d8e-9f00-112233445566` with no added escapes. EVAL-002: the same ledger plus a planted line still lists only that session, and the file still has 2 lines. EVAL-OBS-001 is the empty case, accounted for below. It is not a failed journey.

## Attack
**Disposition: passed, no violations.** Bound to `6f75307`. The transcript hash matches the manifest. Local CLI, scratch ledger, stub `claude`, nothing destructive.

ATTACK-001: eight planted lines, `sessions` prints `none found`, JSON has 0 entries, `resume` exits 1. ATTACK-002: `resume_command` for `x; touch PWNED5` is shell-escaped, the stub is invoked with that text as one argument, and no PWNED file is created.

The attack handoff says this pass was the same session that implemented the change. Review then read the code, re-ran `test/session_id_quoting_test.rb` (2 runs, 0 failures), and probed `trusted?` and `resume_command`. This judgment probed the same two methods and did not repeat the shell. That limit is recorded below. It is not a reason to discard the artifacts.

## Documentation
`10-user-documentation` and `11-faq-index` are `pending`. Both phases are optional, and this change did not start them. That is not a missing explanation of a new command. For an id in the alphabet `Shellwords` leaves alone, the printed command is the same as before, which EVAL-001 shows. A line that fails the check is omitted, which is the intake decision to skip rather than warn. No README or help text was edited, and review did not treat that as a hole. Accounted for.

## Observability
`12-observability` is `pending` and optional. `surfaces.observability` is false. Review's operations note finds no deployed service and no new production failure mode: a rejected line is skipped, and `resume` with no trusted match still exits non-zero and names `soft-foundry sessions`. No alarm or dashboard is owed. Accounted for.

## Review findings
`13-review` is complete. Its handoff is bound to `d08f74e79af9408d0d34524b803ffc57ae279911`; the prose is in `c34f65c`. No `lib/`, `exe/`, or `test/` diff since `d08f74e`. The handoff's `findings` list is empty. `consolidated.md` reports no blocking findings and no unresolved findings. This judgment agrees.

Functional, architecture, and security conform. Accessibility conforms on the declared surface: prefixes, status words, and the recorded-sessions text node are unchanged, and a normal id is not newly escaped. Policy conformance is N/A (`surfaces.policy` is false; the review found no policy text owed; `human_decisions` is empty). Infrastructure is N/A. Operations is N/A for a deployed service.

The specify phase was skipped, so the go-live accessibility advisory about a missing `category: accessibility` requirement still applies. Review said that advisory is not a defect in the review. It is not a failed requirement of this change, and it is not undischarged.

Residual concerns review left for this judgment:

- An id that matches `SessionLedger::ID` and starts with a hyphen (`--help`, `-rf`) is trusted, and `Shellwords.escape` leaves it unchanged. Confirmed on this worktree: `trusted?("--help")` is true and the command is `cd /tmp && claude --resume --help`. The same is true for `-rf`. `record` already accepts that alphabet. This probe did not run `claude`, `codex`, or `grok`. It is not a shell breakout. The shell still runs only the agent binary.
- A line that passes `trusted?` is still shown with the `cwd` and prompt text stored on it. `record` strips control characters on write (`text` and `excerpt`). The read path does not do that again. Out of scope for REQ-SQ-001. The resume command does shell-quote the folder.
- EVAL-OBS-001. When every line is untrusted, `sessions` says `0 recorded` and suggests fewer search words. The attack transcript shows that sentence. The intake chose skip-with-no-warning. The missing-file sentence is a different line.
- Verification, evaluation, and attack were recorded by the implementing session. Review and this judgment were fresh sessions.

`09-remediation` stayed `pending`. Nothing in attack or review required a code change. That is the optional phase behaving as specified, not a skipped fix.

## Residual risk
See `residual-risk.md`. REV-SEC-001, as the parent judgment described it, is closed: a session id that is not the identifier `record` already enforces is not returned, and an id that reaches `resume_command` anyway is shell-quoted. What a maintainer accepts by merging is the narrower leftover: a flag-shaped id inside that alphabet is still pasted as an argument, and a hand-edited `cwd` or prompt on an otherwise trusted line is still printed as stored.

## Reasoning
Every phase this change required is complete. Discovery, specification, threat model, and plan are `pending` and waived in `metadata.yml` `skipped_phases`, each with a rationale. Remediation, user documentation, FAQ index, and observability are optional and were not started. None of those four leaves REQ-SQ-001, REQ-SQ-002, or REQ-SQ-003 unmet. Verification, evaluation, and attack describe `6f75307`, which is the application code at the judged commit. Review describes that same code.

`BLOCKED` would be the outcome if a stated requirement were unmet, if attack had found a violation, or if review had returned blocking findings. The shell-metacharacter paste path named in the intake is closed, by the filter and by the quote. ATTACK-001 and ATTACK-002 denied it. The probe on this worktree agrees: shell syntax, a command substitution, a backtick, a newline, a non-string id, a bogus agent, and a missing `cwd` are not trusted, and `resume_command` still quotes the id and does not insert the agent text.

`REJECTED` does not fit. The three requirements are a sound narrowing of the parent residual, and the implementation matches them.

`APPROVED` does not fit either. `ID` includes a leading hyphen, `trusted?` returns true for `--help` and `-rf`, and the printed command places that token where the agent program parses arguments. Review recorded that as residual risk, not as a miss of this fix. Closing it would be a tighter alphabet or an end-of-options marker, which these requirements do not ask for. It is accepted here, not sent back. The hand-edited `cwd` and prompt case is the same kind of leftover: real, out of scope, and named so it is not silent.

That is **APPROVED_WITH_RESIDUAL_RISK**.
