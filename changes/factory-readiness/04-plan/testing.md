# Test Plan

## Unit
- `test/factory_readiness_test.rb`: UTF-8 reads under a US-ASCII default external encoding; gated-track specification lock (pass, fail on edit, stale downstream); fresh-context advisory for verification, evaluation, attack; `waivers permitted` by risk and the never-waivable phases; `check` lint of `waivable_by_risk`; `change close` judgment refusal and `--force`; guard self-protection in block and warn modes; block-mode refusal text.
- `test/harness_eval_test.rb`: case loading and validation (unknown kind, unknown check, bad regex, escaping path); a gate case that passes; a gate case whose expectation is wrong (reported fail, exit 2); a crashing case (error, scratch removed); a live case with a fake shell that writes a matching finding (pass, line names shell and model); live without `--live` (skip), without `--shell` (error), non-zero shell (error); `--json` shape; `ci` fails when a case fails.
- Existing tests updated: `test/guard_test.rb` and others that read the default mode set `SOFT_FOUNDRY_GUARD=warn` where warn is what they test; fixtures that waive judge or review change to complete them or to a low-risk allowed waiver.

## Integration
- `test/application_repo_test.rb`: the Rails-shaped journey of REQ-FR-008 in-process (`init` from this repository's source, profile, `change new`, `check`, guard decisions, `gate intake`, `eval`).
- The shipped eval suite itself, run by `ci` in this repository and in the application fixture.

## Acceptance criteria coverage
| Criterion | Test layer | Planned test |
| --- | --- | --- |
| AC-FR-001 | unit + suite | `factory_readiness_test` UTF-8 cases; the whole suite under `LANG=C` recorded in verification |
| AC-FR-002 | unit | scrubbed invalid byte |
| AC-FR-003 | unit | lock fails on edit after specify commit |
| AC-FR-004 | unit | verify stale after specification change |
| AC-FR-005 | unit | lock passes unchanged; vetted path unchanged (existing `lifecycle_tracks_test`) |
| AC-FR-006 | unit | advisory for verify/evaluate/attack without executed_by; none with fresh_context |
| AC-FR-007 | unit + integration | block-mode refusal text; `doctor`/`hooks install` mode line; application fixture |
| AC-FR-008 | unit | warn override still allows |
| AC-FR-009 | integration | `eval` in this repository: every case passes, exit 0, `--json` |
| AC-FR-010 | unit | wrong expectation reported fail, exit 2 |
| AC-FR-011 | unit | unparseable case: `check` error, `eval` error and continue |
| AC-FR-012 | unit | crashing case: error, temp dir removed |
| AC-FR-013 | unit | fake-shell live case passes with shell and model named |
| AC-FR-014 | unit | skip / error(--shell) / error(exit status) |
| AC-FR-015 | evaluation | `eval --live --shell claude` transcript (EVAL) |
| AC-FR-016 | unit | waivers by risk, judge/review never |
| AC-FR-017 | unit | `change close` refusal and `--force` |
| AC-FR-018 | unit | `check` lint of the rule |
| AC-FR-019 | integration + evaluation | `application_repo_test`; the hand-run journey transcript (EVAL) |
| AC-FR-020 | unit + review | status word assertions on new lines; accessibility review |
| AC-FR-021 | review | documentation read against the code |

## Not covered and why
The live eval on `codex` and `grok`: neither shell is installed here; the fake-shell test covers the runner's handling and the `claude` run covers one real shell.
