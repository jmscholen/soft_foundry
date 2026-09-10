# Implementation Log

## Changes made
- `lib/soft_foundry/maturity_scan.rb` (new): deterministic detector for languages, frameworks, testing, and infrastructure from file presence; maps findings to the maturity capabilities file presence can honestly answer (roughly levels 1-2); writes `.ai/repository.yml` via `SafeWrite`.
- `lib/soft_foundry/control_plane.rb`: `score_maturity(capabilities)` computes `current_level`/`current_id`/`gaps` from `.ai/maturity.yml`'s levels and scoring rule, shared by every assessment mode so the rule lives in one place.
- `lib/soft_foundry/maturity_deep_assess.rb` (new): shells into an installed `claude` CLI (`claude -p "<prompt>"`, argv-only, no shell interpolation) to run `repository-discovery`'s real skill with judgment. Injectable runner for testability; a proper timeout that kills the subprocess rather than blocking `.value` indefinitely (an earlier draft had this bug — fixed before it shipped, see decisions.md); distinguishes a timeout from a normal failed exit; reports a clear message rather than silently succeeding when the target file was not written or not updated.
- `lib/soft_foundry/onboarding.rb`: `assess_maturity` (public) checks `.ai/repository.yml`'s `assessed` flag first and skips unless `--reassess`; otherwise dispatches to scan or deep mode. Guards against `.ai/` not being installed at all, reporting a clear message instead of a raw filesystem exception.
- `lib/soft_foundry/cli.rb`: `--maturity=scan|deep|off` (default `scan`) and `--reassess` on both `onboard` and `init`. `init` calls `assess_maturity` independent of `--no-onboard`, since that flag concerns provider discovery (network) and has nothing to do with an offline scan.
- `README.md` documents the flags and the honest boundary between what `scan` can and cannot determine.

## Decisions
| Decision | Reason |
| --- | --- |
| `scan` never claims a capability beyond level 2 | Levels 3+ require proof a change went through the lifecycle (specs, verification, attack, judgment); no file-presence scan of an unstarted repository can manufacture that honestly. |
| `deep` invokes `claude` with the prompt as a separate argv element, never shell-interpolated | The prompt is a fixed constant (no repository content is interpolated into it), so this is defense in depth rather than a response to a concrete injection path, but it costs nothing and matches how the rest of the codebase treats subprocess invocation. |
| `deep` never passes a permission-bypass flag | The one file it needs to write outside a change context is already an explicit exception in `repository-discovery`'s own `permissions.yml`; broadening real permissions to make headless execution convenient was rejected. |
| Maturity assessment decoupled from `--no-onboard` | Found via a failing test: `--no-onboard` was designed to skip network calls during provider discovery; `scan` mode is offline and has nothing to do with that flag, so conflating them made `init --no-onboard` silently skip a free, valuable check with no way to get it back except `soft-foundry onboard` separately. |
| `assess_maturity` checks `.ai/` is installed before doing anything else | Found via a failing test: an existing test called `Onboarding#run` directly on a repository that was never `init`'d, and the code crashed with a raw `Errno::ENOENT` reading `.ai/maturity.yml` instead of a clear message. |

## Deviations from plan
None. No separate planning phase ran for this change (see `00-intake/assumptions.md`); this log is the record of what was built.

## Challenges
Three real bugs were found and fixed while building this, all caught by tests or a genuine end-to-end run rather than by a separate review pass:
1. A timeout-handling bug in the first draft of `MaturityDeepAssess#real_run`: after a timed-out `join`, the code went on to call `wait_thr.value`, which blocks until the process exits - defeating the timeout entirely for a genuinely hung subprocess. Fixed before any test exercised the real timeout path, but worth recording since it is exactly the kind of bug that only shows up under real hang conditions, not a quick manual check.
2. The `--no-onboard`/maturity conflation described above.
3. The missing-`.ai/` crash described above.
