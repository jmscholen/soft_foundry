# Evaluation Results

Commit SHA: 2af76ba9b26be41af5bcafa12ee56eda635f6c77
Size: `full_route_sweep`

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 the committed hook on this session's own calls | REQ-GDH-001, REQ-GDH-002 | pass | `evidence/guard-live.txt` |
| EVAL-002 `doctor` and a fresh install compared with the committed hooks | REQ-GDH-001 | pass | `evidence/doctor.txt`, `evidence/hooks-match.txt` |
| EVAL-003 rerunning `hooks install --claude` on the old settings | REQ-GDH-001 | pass (13 of 13) | `evidence/hooks-upgrade.txt` |
| EVAL-004 every claim in the policy header against the guard | REQ-GDH-002 | pass (84 of 86 checks; the 2 are wrong expectations in the script, below) | `evidence/guard-claims.txt`, `evidence/glob-outside.txt` |
| EVAL-005 `mode: off` written in a file as the header spells it | REQ-GDH-002 | **fail** | `evidence/yaml-off.txt` |
| EVAL-006 `.ai/harness-evals/README.md` | REQ-GDH-003 | blocked: denied to this skill | none |
| EVAL-007 README.md as it stands | REQ-GDH-004 | blocked: not written yet, the documentation phase follows | `evidence/readme-state.txt` |
| EVAL-008 every CLI route, plus `check`, `eval`, `ci` and the diff from `main` | REQ-GDH-005 | pass (57 of 62 routes as expected; the 5 are wrong expectations or this sandbox, below) | `evidence/route-sweep.txt`, `evidence/update-route.txt`, `evidence/check-eval-ci.txt` |
| EVAL-009 CLI output against the accessibility rules | accessibility | pass | `evidence/doctor.txt`, `evidence/route-sweep.txt`, `evidence/guard-claims.txt` |

**REQ-GDH-001 and REQ-GDH-005 are proven.** REQ-GDH-002 holds for every claim but one: the `off` value cannot be written in a file as the header spells it (EVAL-005). REQ-GDH-003 and REQ-GDH-004 are not evaluated here: one is denied to this skill, the other is not written until the documentation phase, which comes after evaluation in the lifecycle.

## What the journeys showed

### EVAL-001: the hook this repository has committed, in this session
The hook refused six of this session's own calls before they ran: two Bash commands naming the guard's configuration and protected policy, a Grep and a Glob into `.ai/harness-evals`, a Write outside the repository, and a Write into `02-specification`. The Grep and Glob refusals are what the Grep|Glob matcher in `b9f4d7c` adds; before it, those two tools were not sent to the hook at all. Reads of the configuration files, writes under this phase directory, and shell commands naming no denied path were allowed. Each refusal is in the guard log with `skill=evaluation`.

Two Edit probes with an `old_string` that does not occur in the file never reached the hook: Claude Code validates an Edit's input before PreToolUse hooks run, and such an Edit fails in the host. Nothing was written, and a Write that could apply was refused (item 6 of the evidence). Recorded as EVAL-F-006 for the documentation phase, not a defect.

### EVAL-002 and EVAL-003: the install
`doctor` on this checkout prints `pass guard hook (claude: installed, codex: installed; mode: block, repository policy (.ai/policies/enforcement.yml))`; the command exits 2 on the three machine-local lines verification already recorded as VER-001 (no `.ai/manifest.yml`, no pre-commit hook, no `.soft-foundry/runtime.yml`), which this change does not touch. A fresh install of both hooks equals the committed files.

A repository in the state this one was in before `b9f4d7c` (old matcher, no PostToolUse) is brought to the current install by rerunning `hooks install --claude`: one guard entry with the new matcher, the PostToolUse entry added, an unrelated hook entry and an unrelated `permissions` key untouched, a baseline left by an interrupted call cleared, and a second run leaving the file byte-identical. `doctor`'s fail line, once both hooks are removed, names the command to run.

### EVAL-004: the header's claims
Every claim a command can check holds: the per-tool checks, Grep and Glob by path and static prefix, symlinks resolved, the segment-by-segment reading of a shell command through `cd`, `pushd`, globs, braces and absolute paths (into the root and after leaving it), refusal of deny_read paths, of deny_write paths the skill may not read, of protected policy and harness material, and of the guard's own configuration (including everything under `.soft-foundry/`), allowance of what the skill may read, refusal of what cannot be decided (an unknown `~user`, a NUL byte, unreadable stdin), the baseline before a shell call and the restore after it (policy, override and hook settings restored byte for byte, the mode read after the restore, the missing-baseline fallback to the committed policy, a change between calls standing, a stale baseline refreshed, no baseline for a write-tool call), the three modes and their precedence with the variable winning and `doctor` naming the source, nothing guarded on `main` or once the change is closed, and the Codex and Grok tool names the README describes.

Two of the script's 86 checks reported `UNEXPECTED`, both wrong expectations in the script, kept as printed:
- "no baseline before the first shell call": the Bash payloads fed earlier in the script had each recorded a baseline, exactly as the claim says every shell call does.
- "Write .ai/rules/ruby.md (a write tool call)" expected a refusal: the override file written two checks earlier as the maintainer's own change was still in place, so the call was reported in warn mode and allowed, which is the claim under test there. The assertion that mattered, no baseline after a write-tool call, passed.

### EVAL-005: `off` in a file
`YAML.safe_load("guard:\n  mode: off\n")` returns `{"guard"=>{"mode"=>false}}`: a YAML 1.1 parser reads an unquoted `off` as a boolean, `Guard.mode` sees `false`, which is not a mode, and falls through. A policy written `mode: off` reports `warn, default`; an override written `mode: off` under a block policy reports `block, repository policy`. Quoted, `mode: "off"` works, and `SOFT_FOUNDRY_GUARD=off` works. The header lists `off` among the values of the file without saying it must be quoted; the README's existing text says the same and REQ-GDH-004 will carry it forward. The failure is toward the stricter mode in both cases, so nothing is exposed, but the claim is not reproducible as written. EVAL-F-001.

### A defect met on the way (EVAL-F-002)
Retrying a command in this session, the hook refused `cd /tmp/sf-eval-sweep-*/app 2>/dev/null && ...` with `could not be decided (NoMethodError: undefined method 'empty?' for nil)`. Pinned in `glob-outside.txt`: globs are not the cause; a `cd` or `pushd` that leaves the root followed by any further token in the same segment (a redirection target, typically) is. `shell_paths` computes `base` once per segment and then reads `cwd.empty?` for the next token after the `cd` has set `cwd` to nil (`lib/soft_foundry/guard.rb` lines 486 to 505). `cd /tmp 2>/dev/null && ls`, `pushd /tmp >/dev/null && ls` and `cd .. 2>/dev/null && ls` are refused; `cd /tmp && ls` and `cd lib 2>/dev/null && ls` are decided. The guard fails closed as the header promises, so this is a refused legitimate command, not a bypass; it is a code change for a later record (REQ-GDH-005 forbids one here).

### EVAL-007: the README today
The README's guard section still says Bash is checked against the deny sets "and passes everything else" and names neither Grep nor Glob; it has no mention of the post-call restore, `guard --after`, an interrupted command, how a shell command is read, or an undecidable call, and the harness-evals section has no live-eval shell arguments. `readme-state.txt` lists each item with its line count (zero for all but `.soft-foundry/`, which appears for other reasons) and quotes the section as it stands. Review must read the README the documentation phase writes against REQ-GDH-004 and against EVAL-F-001 and EVAL-F-002; a DOCS edit does not stale this evidence (VER-003).

### EVAL-008: every route
`route-sweep.txt` records 57 routes as expected and 5 `UNEXPECTED`, a raw count kept as the script printed it. None is a defect:
- `doctor` exit 2 right after `init`: the guard and pre-commit hooks were not installed yet and the policy is block; with the hooks installed it exits 0 (the second `doctor` in the same sweep, and `doctor.txt`).
- `gate all` exit 0 and `change request-discharge` exit 0: nothing had failed and nothing was undischarged (release-0-23-0's sweep met the same two).
- `phase run evaluate attack --parallel --dry-run` exit 1: refused for an unmet predecessor, which is correct; the parallel dry run's success path was not reached (as in release-0-23-0).
- `update` exit 1, HTTP 403: this sandbox's proxy, not the route; rerun with the session's placeholder token it is HTTP 401, while `gh api` and a raw `curl` of the same URL reach GitHub (`update-route.txt`). Nothing in this change touches `update`.

No route printed crash text or an ANSI escape; `ui` answered 401 without the token and 200 with it on every API route and was stopped. On this checkout `check`, `eval` (28 passed, 1 live case skipped) and `ci` pass, and the diff from `main` outside `changes/` is the three files of `b9f4d7c`.

## Failures
- **EVAL-005** (REQ-GDH-002): `mode: off` unquoted in the policy or the override is read as the boolean false and ignored. EVAL-F-001, minor.
- **EVAL-F-002** (code, out of this change's scope): the guard's shell parser raises on a `cd` out of the root followed by another token in the same segment and refuses the command as undecidable. Minor, fails closed.

## Limits of this evidence
- REQ-GDH-003 was not read: `.ai/harness-evals/**` is in this skill's deny_read set, as in verification's (VER-002). Judgment must name it as unchecked by the lifecycle.
- REQ-GDH-004 could not be evaluated: the README text is written by the documentation phase, after this one. EVAL-007 records what is absent today so review can check each item was added.
- The post-call restore was exercised only against a scratch repository's configuration (EVAL-004), never this repository's, which this skill may not change. The one post-call line in this repository's guard log during verification ("tamper restored= (no baseline; committed policy used)") shows the committed PostToolUse hook running here.
- The routes ran from this checkout's library in a scratch repository, not from an installed gem; `phase run` was run only with `--dry-run`; `--panel` and `eval --live` were not run.
- The scratch repositories under the system temp directory were created by the evidence scripts from Bash and removed afterwards; the Write tool refused the scratchpad, so the scripts live under `evidence/scripts/`.

## Accessibility observations
`surfaces.accessibility` is true. The CLI output rules of `.ai/rules/accessibility.md`:
- Every outcome is carried by a word: `pass`, `fail`, `warn`, `skip` on `doctor`, `gate`, `check`, `eval`, `ci`, `scan`; `installed`, `removed` on `hooks`; `✗ fail guard:` and `! warn guard:` on every refusal and warning, the glyph accompanying the word. A screen reader or a log stripped of non-ASCII keeps the meaning.
- No ANSI escape was emitted to a pipe: `doctor.txt` contains none (grep count 0) and the sweep's ANSI check flagged none of the 62 routes.
- Output is line-oriented with stable prefixes (`guard:`, `billing:`, `advisory:`, `summary:`, `ui:`); nothing depends on terminal width.
- No route prompted: every route ran with stdin closed and returned.
- Error messages say what to do next: a refusal names the tool, the path, the skill, the mode, and where the override is documented; `doctor`'s guard line, when the hook is missing, names the install command; the post-call refusal names the files restored and the log.
- Keyboard-only operation, focus order and visible focus: no interactive control exists for them to apply to; every decision is a flag, and the sweep drove every route with stdin closed.
- Document rules: the policy header is a plain-text comment in short paragraphs. The README text REQ-GDH-004 owes is not written yet; review's `accessibility.md` must examine it (heading hierarchy, descriptive link text, code blocks for commands).
