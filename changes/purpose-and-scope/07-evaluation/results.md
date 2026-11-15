# Evaluation Results

Commit SHA: d272a5f538034b51e0e7264a4b2e81aadce1c87e (HEAD, `Record purpose-and-scope verify`). Outside `changes/` it is identical to the implementation commit d944d07.

Size: `full_route_sweep` (`soft-foundry change size --phase evaluate`: no scope declared). Read here as every document the change edited plus every read-only entry command of the tool; `evaluation-plan.md` says which commands were left out and why.

Every document was read with `git show <commit>:<path>`. The tool commands ran in a clean clone of the commit with provider keys and `SOFT_FOUNDRY_PHASE` unset.

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 Adopter reads `README.md` from the top | AC-001, AC-004 | pass | evidence/eval-001-readme.txt |
| EVAL-002 Agent reads `.ai/README.md` from the top | AC-001 | pass | evidence/eval-002-ai-readme.txt |
| EVAL-003 Fresh attack session reads its skill | AC-002 | pass | evidence/eval-003-attack-skill.txt |
| EVAL-004 Fresh review session reads its skill | AC-003 | pass | evidence/eval-004-review-skill.txt |
| EVAL-005 The four documents agree | AC-001, AC-002, AC-003 | pass | evidence/eval-005-consistency.txt |
| EVAL-006 Added text read without layout, colour or glyphs | AC-005 | pass | evidence/eval-006-accessibility.txt |
| EVAL-007 Maintainer runs the tool after the edit | AC-006 | pass | evidence/eval-007-diff.txt, evidence/eval-007-tool-smoke.txt, evidence/eval-007-baseline.txt |

Acceptance criteria as the reader meets them:

| Criterion | Tier | Result | What the reader finds |
| --- | --- | --- | --- |
| AC-001 | must | met | In both README files `Purpose` is the first section after the title and its one-paragraph introduction, ahead of every section on commands or layout. By the end of it the reader has been told: autonomous software factory; what each gate checks is locked once a person approves it; verification, evaluation and attack look at the feature from the outside. |
| AC-002 | must | met | A session with only the attack skill can answer who the attacker is (an outside party reaching the change through requests, parameters, uploads, jobs, webhooks, command arguments), what to try (nine numbered classes, in REQ-002's order), and what to do with a repository-write weakness (out of scope; a follow-up in the handoff notes, not an attack result, no severity). |
| AC-003 | must | met | A session with only the review skill is told a finding that needs write access to the repository is never graded blocking or major and is recorded as a follow-up. The file the paragraph points to exists. |
| AC-004 | should | met | `README.md` Purpose names the three points where a person steps in and says the lock is lock and detect: the gate fails when a locked file changes. |
| AC-005 | should | met | One level-1 heading and no skipped level in each file; every added byte is printable ASCII; no link, image, table or colour word added; nothing is lost when markup is removed. |
| AC-006 | should | met | No path under `lib/`, `exe/` or `test/` differs from the intake commit; `soft-foundry check` and `soft-foundry ci` exit 0. |

## Failures
None. No journey failed and no criterion is unmet.

Two commands in the EVAL-007 sweep exit non-zero, and neither is a failure of the change: `soft-foundry help` exits 1, and `soft-foundry doctor` exits 2 on three machine-local items a fresh clone does not have (the install manifest, the pre-commit hook, the local runtime file). Both behave the same at the intake commit (`evidence/eval-007-baseline.txt`).

One defect in this session's own evidence script was found and fixed before the evidence was kept: the first run printed the heading outline with long headings missing (the renderer wrapped them across two lines) and reported the wrong exit status for the comparison in EVAL-005. Both were corrected and every transcript was produced again; the kept files are from the corrected script.

## Advisory findings
These are observations a reader would make. None is an unmet criterion and none is a reason the change fails.

- **EVAL-F1 (minor). "Three points" reads as the whole list, and it is not.** `README.md` line 11 says a person steps in at three points and "Everything in between runs without them". The same file later describes other stops where a change parks at `awaiting_human` until a person decides: a panel that did not agree (line 258) and a policy text change that is owed (lines 361 to 364). `.ai/policies/human-boundaries.yml` lists more (exceeding the budget cap, deploying beyond the development environment, weakening a required control, which this very change needed). A reader who stops at Purpose would expect no other stop. REQ-004 asked for exactly these three points, so the text does what was specified; the sentence "Everything in between runs without them" goes further than the specification asked and is the part that overstates. `.ai/README.md` does not carry that sentence.
- **EVAL-F2 (minor). The nine classes may read as the full list of what to attack.** The attack skill's opening paragraph (line 3) and its section "Purpose of ATTACK" (line 43) still name replay, concurrency, malformed or large input, dependency failures and retry behavior, which are not among the nine classes of "The attacker". The new section says "Try each class that applies to it" and does not say whether the list is complete. A fresh attack session could read it either way. Nothing in the file contradicts AC-002.
- **EVAL-F3 (minor). `README.md` now opens with two descriptions of what Soft Foundry is.** Line 3 calls it "a repository-native control plane for autonomous software engineering" with "eventually enforced lifecycle orchestration"; line 7 calls it "an autonomous software factory". They do not contradict each other, but a newcomer meets two openings four lines apart, and "eventually" in the first no longer matches a tool that gates and seals phases today.
- **EVAL-F4 (minor, not caused by the change; needs a person). The worktree still holds two uncommitted control-plane files.** `.ai/policies/enforcement.yml` and `.claude/settings.json` differ from HEAD exactly as 06-verification's VER-001 describes: `settings.json` is without the `PostToolUse` hook entry and without `Grep|Glob` in the `PreToolUse` matcher, and the header of `enforcement.yml` is an older text. `guard.mode` is still `block`. They were in that state when this session started; this session did not edit them and may not restore them (both are outside its write set). The evidence here does not depend on them: documents were read from the commit and the tool ran in a clean clone. They should be put back to HEAD before any later commit. The seal commits only the phase directory and `metadata.yml`, so it should not pick them up.

## Accessibility observations
`surfaces.accessibility` is true. The result is Markdown text.

- **Keyboard-only operation, focus order, visible focus, error behavior: not applicable.** The change adds no control of any kind: no link, form, button, command or output. A reader moves through the text with whatever viewer they already use.
- **Structure a screen reader can navigate: pass.** Each edited file has one level-1 heading and no skipped level. The three new headings (`Purpose` in both README files, `Skills and modes`, `The attacker`) are level 2 directly under the title, and each says what its section holds. In `.ai/README.md` the text that used to follow the introduction without a heading now has one.
- **No meaning by colour or symbol alone: pass.** Every added byte is printable ASCII and no colour is named. Emphasis is used for the three lead-in sentences of Purpose; with the emphasis removed they remain complete sentences and the text reads the same. The nine attack classes are an ordered list whose numbers only give the order. "Out of scope" is said in words.
- **Link text and alternative text: nothing to judge.** No link or image was added. Paths are given as inline code, which a screen reader reads as text.
- **Reading load, an observation only.** The bullets in Purpose are four to five sentences each. They read clearly in order; a reader skimming by the bold lead-ins gets the three ideas.

What was not evaluated: how the Markdown looks in a particular hosted renderer (contrast, zoom, reflow), which belongs to the viewer and not to this text; and the commands that write records, listed in `evaluation-plan.md`.
