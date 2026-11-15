# Verification Results

Commit SHA: 4b693c70bf13d79ba2e35d4bab6d8483421ba582 (HEAD, `Record purpose-and-scope implement`). Outside `changes/` it is identical to the implementation commit d944d07. Tree abc470e31ae1e67b54f4e57ca7adb2e57e4642ae.

Size: `full_at_verify` (`soft-foundry change size --phase verify`: no scope declared). The full suite was run.

Where the checks ran: CHECK-002, CHECK-003 and CHECK-004 ran in a clean clone of the commit in a temporary directory, on branch `change/purpose-and-scope`, with no uncommitted paths. CHECK-001 ran in the worktree but reads every file with `git show <commit>:<path>`. The worktree itself was not used for the other checks because two files in it differ from HEAD (VER-001 below).

Environment: ANTHROPIC_API_KEY, OPENAI_API_KEY, XAI_API_KEY, GEMINI_API_KEY, MAILTRAP_API_KEY, PERSONAL_SENDGRID_API_KEY and SOFT_FOUNDRY_PHASE unset. Ruby 3.3.1.

## Deterministic checks

| Check | Command | Result |
| --- | --- | --- |
| CHECK-001 | `ruby evidence/content_checks.rb 4b693c7 49b2ae5` | pass: 45 assertions, 0 failed |
| CHECK-002 | `ruby -Ilib exe/soft-foundry check` | pass: 16 phases, 17 skills, no errors |
| CHECK-003 | `ruby -Ilib exe/soft-foundry ci` | pass: harness eval 35 passed, 1 live case skipped; every record passes |
| CHECK-004 | `bundle exec rake test` (full suite) | pass: 935 runs, 6880 assertions, 0 failures, 0 errors, 0 skips |

Acceptance criteria, each against the text at the commit:

| Criterion | Tier | Result | What was checked |
| --- | --- | --- | --- |
| AC-001 | must | met | In `README.md` and `.ai/README.md`, `## Purpose` is the first section after the title, ahead of every section on commands or layout. Each states "autonomous software factory", "What each gate checks is locked once a person approves it", and that the evidence phases look at the feature from the outside. |
| AC-002 | must | met | `.ai/skills/adversarial-testing/SKILL.md` names the attacker as an outside party reaching the change through what it exposes (requests, parameters, uploads, jobs, webhooks, command arguments), lists nine numbered classes in REQ-002's order, and puts repository-write editing of the change record, the control plane or git history out of scope, noted as a follow-up and not recorded as an attack result. |
| AC-003 | must | met | `.ai/skills/review/SKILL.md` says findings are graded against the attack threat model, a finding that needs write access to the repository is never graded blocking or major, and it is recorded as a follow-up. |
| AC-004 | should | met | `README.md` Purpose names the three points where a person steps in and says the lock is lock and detect. `.ai/README.md` says the same. |
| AC-005 | should | met, in part by a mechanical check | See the note below. |
| AC-006 | should | met | 75 paths differ from the intake commit 49b2ae5; none is under `lib/`, `exe/` or `test/`. Outside `changes/` only the four edited files differ. `check` and `ci` pass. |

AC-005: the four edited files each start with one level-1 heading and skip no heading level. None holds a hidden or control character, and `soft-foundry check` (which scans `.ai/` and the pointer files) passes. The 38 added lines are plain ASCII, name no colour, and hold no link. "No meaning rests on a symbol alone" is a reading judgment: the script shows that no glyph or colour word is present, which is the mechanical part. The accessibility review in `13-review/accessibility.md` owns the judgment.

RED/GREEN: no check records a `red_commit`. The change is text only, no test was written for it, and nothing under `lib/`, `exe/` or `test/` changed.

Access control: the repository profile declares no `access_control` paths, so no check states a protection.

## Failures

No check of the change failed. Two runs did not finish cleanly and are recorded here.

- **`ci` in the clone, first run: exit 2.** It reported `process-speed` as "merged into change/purpose-and-scope but status is 'judged', not 'closed'". The cause was the clone, not the change. `git clone` of the worktree set `refs/remotes/origin/HEAD` to this branch, and `Git#default_branch` (`lib/soft_foundry/git.rb`) reads that ref first, so `ci` took this branch as the default branch. The worktree has no such ref and falls back to the local `main`. With the ref removed from the clone and local `main` at 3fd048c (the same as the worktree), `ci` exits 0. The failed output is kept as `evidence/ci-clone-default-branch-artifact.txt`; the passing run is `evidence/ci.txt`.
- **Full suite, first run: stopped by the session's time limit** after about 927 tests with no failure or error printed. Its output was overwritten by the second run, which finished: 935 runs, 0 failures. The first run had SOFT_FOUNDRY_PHASE=verify set; the second had it unset.

## Findings

- **VER-001 (not caused by the change; needs a person).** During this session's first shell command, which only read files, the guard's post-call hook reported that `.ai/policies/enforcement.yml`, `.soft-foundry/enforcement.yml` and `.claude/settings.json` "changed during the tool call and were restored to the state before it". After that, `git status` shows `.ai/policies/enforcement.yml` and `.claude/settings.json` modified against HEAD. The diff is an older text of both: the header of `enforcement.yml` loses the paragraphs on Bash, the guard's own configuration and the post-call restore, and `settings.json` loses the `PostToolUse` hook entry and `Grep|Glob` from the `PreToolUse` matcher. `guard.mode` is still `block`. I did not edit either file and did not put them back: both are outside this skill's write set. The evidence here does not depend on them because it came from a clean clone of the commit. They are not part of what the seal commits, but they should be put back to HEAD (`git checkout -- .ai/policies/enforcement.yml .claude/settings.json`) before any later commit, and the guard's baseline looks worth a look: a restore that writes an older file over a committed one is the opposite of what it is for.
- **VER-002 (minor).** The full suite takes about 21 minutes (1288.8 s here, 1114.8 s in process-speed's record) and this change is four text files. The size is `full_at_verify` only because `metadata.yml` declares no scope.
- **VER-003 (minor).** AC-005 was checked by script for heading order, hidden characters, ASCII-only added text, colour words and links. Whether any meaning rests on a symbol alone is a reading judgment left to the accessibility review.
- **Note, not a finding.** The assertion count is 6880 here against 6885 in process-speed's record for the same 935 runs. Nothing under `lib/`, `exe/` or `test/` differs between the two commits, so the difference comes from the environment (clean clone, variables unset). No test failed or was skipped in either.

What was not verified:

- That the text reads well to a person, and the symbol-and-colour judgment of AC-005 beyond the mechanical check. Evaluation and the accessibility review own those.
- The guard wrote an ignored `.soft-foundry/` folder inside `06-verification/evidence/` when a command ran from that folder (the same cause as the implementation log's entry). It is ignored by `.gitignore`, is not evidence, and was left alone because no skill may touch the guard's configuration from the shell.

## Evidence

Listed with SHA-256 in `evidence/manifest.yml`:

- `evidence/content_checks.rb`: the script for CHECK-001.
- `evidence/content-checks.txt`: its output.
- `evidence/check.txt`: `soft-foundry check`.
- `evidence/ci.txt`: `soft-foundry ci`, passing run.
- `evidence/ci-clone-default-branch-artifact.txt`: `soft-foundry ci`, the first run that failed on the clone's default-branch ref.
- `evidence/rake-test.txt`: the full suite.

No payload in the evidence holds a hidden or control character, so nothing is shown escaped.

Evidence generated for a different implementation commit is stale.
