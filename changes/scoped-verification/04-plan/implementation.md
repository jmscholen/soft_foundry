# Implementation Plan

## Approach
Add four optional declarations and one decision module, and make every reader follow it.

- Per-record scope: optional `scope:` list of path globs in `metadata.yml`.
- Repository profile keys in `.ai/repository.yml`: `shared_core:` and `access_control:` (path globs).
- A new `lib/soft_foundry/scope.rb` (`Scope`) is the single decision point. It takes the record, the sibling records, the control plane, the git wrapper, and returns one result object: `{stale_reasons: [{path, reason, claimed_by}], size_verify, size_evaluate, size_attack, applied_scope}`. `Gate#staleness_check`, `status`, the phase runner, the snapshot and the new `size` command read this result and add no logic of their own (REQ-019).
- A new policy `.ai/policies/check-sizing.yml` names the sizes and the rules that map diff facts to a size. `Scope` reads it; sizes are not hardcoded in Ruby beyond the ordering of size names read from the policy.
- Default is unchanged: no `scope` (absent or empty) takes the existing code path in `staleness_check` verbatim (REQ-004).

Ordering of the work is the order of the sequence below; each step ends green on the existing suite.

## Implementation sequence
1. **Git wrapper fail-closed** (`git.rb`). Today `changed_since` and `changed_between` return `[]` when git fails, which reads as "no change" (THREAT-007; discovery showed this). Add `diff_paths(sha, tip_or_head)` that returns `[paths, ok]` or raises `Soft_foundry::GitError`, and keep `changed_since`/`changed_between` as the legacy callers for the unscoped path, unchanged in behaviour. Add `tree_of(sha)` (`rev-parse --verify --end-of-options <sha>^{tree}`, exit status checked, SHA validated by the existing `SHA` pattern before use), `blob` reuse for declaration-at-commit reads, and `code_dirty_paths` (one `git status --porcelain --untracked-files=all --ignored=matching`, then filtered in-process to `code_globs`; an ignored directory entry with trailing slash counts as dirty when any code glob prefix overlaps it). All git calls use argument arrays and `--` before paths.
2. **Declarations** (`control_plane.rb`, `change_record.rb`). `ControlPlane#shared_core` and `#access_control` read the profile (empty list when absent). `ChangeRecord#scope` reads metadata (empty when absent or not a list of strings). A shared glob validator `Declarations.problems(list, tracked_files, code_globs, kind:)` returns messages for: empty string, absolute, `..` segment, leading dash, control character or NUL, matches no tracked file (`git ls-files` once), and for `shared_core` matches nothing inside `code_globs`. It uses `ControlPlane.match?`. Confirm in this step that `match?` is `File.fnmatch` plus a prefix test for `/**`: linear in path length, no regex backtracking (MIT-010). Reject patterns over a fixed length and more than a fixed number of `**` or `{}` groups to bound `FNM_EXTGLOB` brace expansion.
3. **Scope decision module** (`scope.rb`). Inputs: record, sibling records (loaded once from `changes/*/metadata.yml`, active only: `status` not closed and well-formed `scope`; closed or malformed records claim nothing, MIT-003), the evidence commit `sha`, the diff base (record branch tip when that branch is not checked out, else HEAD plus dirty paths, same as today). Algorithm, with one `diff_paths` call plus one `git diff --name-only` of declaration files:
   - Unscoped record: return the legacy result (every changed code path is a reason `in scope: whole repository`).
   - Scoped record: for each changed code path classify in this order: `shared core` (matches shared_core), `in scope` (matches record scope), else claimed by another active record's scope (not a reason; name the claimer in the report), else `unclaimed` (a reason). Reasons are collected; stale when any exists.
   - Declaration changes (REQ-013): compare, as of `sha` versus now, the record's `scope` (from `blob(sha, changes/<slug>/metadata.yml)` against current), the profile `shared_core` and `access_control` (from `blob(sha, .ai/repository.yml)`), and the policy file's blob. Any difference is reason `declaration changed` naming the key. A declaration absent at `sha` but present now also counts. Unreadable blob at `sha` fails closed: stale, cause named.
   - Any git failure yields a stale result whose reason names the cause (REQ-016), never current.
4. **Staleness check** (`gate.rb`). `staleness_check` delegates to `Scope`; unscoped records follow the identical existing lines. The failure message keeps the `STALE:` prefix and gains `scope: <applied>` and `path: reason` lines (REQ-020). The specification re-record cause and stacked tip logic stay untouched and run after the code filter exactly as now (REQ-005).
5. **Full-suite check** (`gate.rb`, new `FullSuite` helper). `tests.yml` in the verification directory gains an optional `full_suite:` block: `tree`, `command`, `outcome`, or `cite: <slug>`. Check named `full-suite run recorded (record check, not a test result)` (AC-010). Rules: slug must match the existing record-name pattern, resolve under `changes/` only, not equal the citing record, citation depth one (a cited run must itself hold `tree`, not `cite`). Citing: cited record exists, its recorded `tree` equals `tree_of(citing evidence sha)` recomputed from git, its `outcome` is `passed`, and `code_dirty_paths` is empty. Recording directly: the recorded `tree` must equal `tree_of(evidence sha)`, `command` and `outcome` present. Failure message: `fail: <cause>; run the full suite on this tree and record it in tests.yml`. Absent block with computed size `targeted plus one full` is a skip with a note (the full run is still owed before merge, REQ-012); absent block with computed size `full at verify` fails (see step 6). The check is for the verification gate only.
6. **Sizing** (`sizing.rb`, `check-sizing.yml`, CLI `soft-foundry change size [slug] [--phase verify|evaluate|attack]`). Policy YAML defines size names (`targeted_plus_full_before_merge`, `full_at_verify`, `touched_doors_plus_smoke`, `full_route_sweep`) and rules: verify is targeted when every changed code path is in scope and none is shared core; else full. Evaluate and attack are `touched_doors_plus_smoke` only when a scope is declared, `access_control` is non-empty, and no changed path matches `access_control`; otherwise `full_route_sweep` (REQ-010). Diff base is the same as step 3 (REQ-011). The output prints, one fact per line with a stable prefix: `size:`, `scope:`, `reason:` per triggering path. The gate adds a `check size matches diff` check: verification evidence (`tests.yml` key `size:` in the new block of template, or in the manifest) recording a size ranked lower than computed fails naming both (AC-012). A missing recorded size on a scoped record fails with the fix named; an unscoped record computes full and passes the existing flow unchanged.
7. **Advisories** (`advisory.rb`). Three lines, none blocking: diff touches paths outside the declared scope; shared core touched and no `full_suite` in verification; declared scope matched no changed file after work; plus overlap of scopes between active records (MIT-003).
8. **Consumers** (`phase_runner.rb`, `snapshot.rb`, `ui/`, `cli.rb status`). They call the existing `stale?` on the gate result; the only edits are surfacing `applied_scope` in `change status` and in the snapshot, rendered in text and HTML-escaped. Add a test asserting no second staleness implementation exists (a record is not stale in `status` and fresh in `phase run`).
9. **Structure check** (`check.rb`). Validate `check-sizing.yml` parses with no aliases or tags (use `YAML.safe_load(aliases: false)` for the new files; the existing loader allows aliases, so do not reuse it for declarations); validate declarations in the profile and in every record; require the template fields; keep the existing checks.
10. **Templates, skills, docs, evals.** `.ai/templates/change/metadata.yml` gets a commented `scope: []`; `.ai/skills/verification/template/tests.yml` gets the `full_suite` block; verification, evaluation and adversarial-testing SKILL.md name the size command; `.ai/workflow.yml` `rules:` names the sizing policy; `.ai/README.md`, `.ai/schemas.md`, `README.md` document the fields, the policy, and the sentence that a passing gate shows a recorded run names this tree, not that the suite passed. Harness-eval cases for stale-in-scope, other-record-current, shared core, tree mismatch (the implementation phase owns these files; this plan does not read them, they are denied to planning).
11. **Dogfood.** This repository declares no `shared_core`, no `access_control`; its records declare no `scope`, so its own behaviour is unchanged (REQ-004).

## Affected files or components
| Path | Change |
| --- | --- |
| lib/soft_foundry/git.rb | fail-closed `diff_paths`, `tree_of`, `code_dirty_paths`; legacy methods kept |
| lib/soft_foundry/scope.rb (new) | the single staleness and reason decision |
| lib/soft_foundry/sizing.rb (new) | size from diff and policy |
| lib/soft_foundry/full_suite.rb (new) | record/cite check |
| lib/soft_foundry/declarations.rb (new) | glob validation shared by check and gate |
| lib/soft_foundry/gate.rb | `staleness_check` delegates; two new checks; `CHECK_DESCRIPTIONS` |
| lib/soft_foundry/control_plane.rb | `shared_core`, `access_control`, bounded `match?` input |
| lib/soft_foundry/change_record.rb | `scope` reader |
| lib/soft_foundry/check.rb | validate declarations, policy, templates |
| lib/soft_foundry/advisory.rb | three advisories plus overlap |
| lib/soft_foundry/phase_runner.rb, snapshot.rb, ui/ | follow the result; show scope as text |
| lib/soft_foundry/cli.rb | `change size`, scope in `status`, `change new --scope` |
| .ai/policies/check-sizing.yml (new) | sizing policy |
| .ai/templates/change/metadata.yml, skills/verification/template/*, SKILL.md of verification, evaluation, adversarial-testing | fields and instructions |
| .ai/workflow.yml, .ai/README.md, .ai/schemas.md, README.md | kept in step |
| .ai/harness-evals/cases/ | new gate cases (implementation owns) |
| test/scoped_verification_test.rb (new), existing gate and stacked tests | see testing.md |

## Application changes
As listed; Ruby standard library and git only (REQ-025). Output contract (REQ-021): outcomes are words (`pass`, `fail`, `warn`, `skip`, `stale`), prefix lines `scope:`, `reason:`, `size:`, `advisory:`; messages end with the next action; no prompts; `NO_COLOR` respected as today.

## Database changes
N/A.

## Infrastructure changes
N/A. CI runs the new checks through the existing gating of records.

## Decisions made in planning
- Active-record claim rule (MIT-003): a record claims paths only if its `status` is not closed and its scope validates. Spec was silent; this is the safer reading because closed records must not hide staleness.
- Declaration-change comparison reads blobs at the evidence commit; no stored copy is trusted.
- Citation depth one, cited `tree` is recomputed against git, not trusted alone.
- Declarations load with a no-alias safe loader; existing records keep the existing loader.
- Sizing policy file edits count as a declaration change.
- Bounded git calls (REQ-024): one `diff --name-only` for code paths, one for declaration blobs at most (`blob` reads for three known files), one `ls-files` only in `check`, one `status` only in the full-suite check. Sibling records are read from disk, no git.

## Risks
| Risk | Plan |
| --- | --- |
| Silent change to the default staleness rule | unscoped path retained verbatim; existing tests pin it; a test runs each existing staleness fixture with and without `scope: []` |
| Legacy `changed_*` swallow git errors | new fail-closed method used by every scoped path; legacy left only for unscoped behaviour; follow-up finding recorded for verification (should the unscoped path also fail closed; out of scope here) |
| Ignored dirs reported with trailing slash | prefix overlap rule plus test |
| `FNM_EXTGLOB` brace blow-up | length and group-count bounds on declared globs |
| Two decision sites disagree | consumers call the module; test compares `status`, `phase run`, gate |
| Wording overclaims | text assertions that no output says the suite passed |

## Test strategy
See `testing.md`: unit tests per module, temporary-repository integration tests per acceptance criterion, existing staleness tests unchanged as the default-behaviour pin.

## Rollout
See `rollout.md`.

## Rollback
See `rollback.md`.
