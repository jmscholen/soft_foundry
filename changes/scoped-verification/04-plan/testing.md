# Test Plan

Tests are Minitest in `test/`, built on temporary git repositories like `test/stacked_branch_test.rb`. A new file `test/scoped_verification_test.rb` holds most cases. The existing staleness tests are not edited; they must stay green and pin REQ-004.

## Unit
- `Declarations.problems`: empty, absolute, `..`, leading dash, NUL/newline, over-long, brace blow-up, match-nothing, shared core outside code groups, and a well-formed list (AC-015).
- `ControlPlane.match?` on `**`, `dir/**`, and hostile patterns completes within a time bound (MIT-010).
- `Git#diff_paths`, `tree_of`: unknown sha and bad ref raise or return not-ok, never `[]` (AC-016).
- `Scope` classification: in scope, shared core, claimed by another active record, claimed only by a closed record (stale as unclaimed), unclaimed, malformed sibling claims nothing.
- `Sizing`: verify, evaluate, attack across scope/shared-core/access-control/none combinations (AC-011, AC-013).
- `FullSuite`: record valid, wrong tree, missing outcome, outcome not passed, cite valid, cite missing, cite self, cite of a cite, hostile slug, dirty code path, ignored-directory overlap (AC-008, AC-009).

## Integration
Temporary-repository tests driving `Gate`, the CLI and the phase runner:
- both unscoped forms stale as before (AC-001); scoped A/B stale and current (AC-002, AC-005); shared core stales both (AC-003); unclaimed stales (AC-004).
- specification re-record and stacked branch unchanged (AC-006); size diff base uses the unchecked-out branch tip (AC-014).
- declaration narrowing after evidence, for scope, shared core, access control and the policy file (AC-007).
- recorded smaller size fails with both sizes named (AC-012).
- advisories printed, gate exit unaffected (AC-017).
- `status`, `phase run`, snapshot agree on a record current for its scope (AC-018).
- captured output with `NO_COLOR` and non-ASCII stripped: words, prefixes, applied scope, paths, reasons, next action, no prompt (AC-019); HTML-bearing glob escaped in the snapshot and UI page, scope and stale in text (AC-020).
- git call counting via a wrapper around `Git#run`: 1 versus 1000 changed files, equal counts (AC-022).
- text assertions across new output and docs that none says the gate proves the suite passed, and the check is named a record check (AC-010).
- `soft-foundry check`, the full suite, and harness evals pass; no new dependency in the gemspec (AC-021).

## Acceptance criteria coverage
| Criterion | Test layer | Planned test |
| --- | --- | --- |
| AC-001 | integration | unscoped and `scope: []` records stale identically, naming the path |
| AC-002 | integration | two-record fixture, change under a/, A stale in scope, B current |
| AC-003 | integration | profile shared core, both stale, reason shared core |
| AC-004 | integration | path under other/, A stale unclaimed; closed-record variant |
| AC-005 | integration | change under b/, A current |
| AC-006 | integration | spec re-record after evidence; stacked branch tip fixture |
| AC-007 | integration | narrow scope, edit core, edit access control, edit policy, each stale declaration changed; unreadable blob fails closed |
| AC-008 | unit + integration | tests.yml tree match, mismatch, missing outcome |
| AC-009 | unit + integration | cite matrix incl. rebase tree miss and dirty path |
| AC-010 | integration | text assertions on output, README, schemas, SKILL text |
| AC-011 | unit + CLI | `change size` for in-scope and shared-core diffs lists paths |
| AC-012 | integration | recorded targeted vs computed full fails naming both |
| AC-013 | unit + CLI | access-control touched or not; no globs; no scope |
| AC-014 | integration | non-checked-out branch tip diff base |
| AC-015 | unit + check | declarations matrix through `soft-foundry check` |
| AC-016 | unit + integration | unknown sha, deleted branch, stubbed git failure with empty output |
| AC-017 | integration | three advisory fixtures, gate still exits success |
| AC-018 | integration | status and phase run refuse as not stale |
| AC-019 | integration | stripped-output assertions |
| AC-020 | integration | snapshot/UI text, escaped HTML glob |
| AC-021 | integration | check, suite, harness evals, gemspec dependency list |
| AC-022 | integration | counted git invocations at 1 and 1000 files |

Threat coverage for attack phase: AC-X1..X10 are realised by the attack phase as fixtures; the unit tests above are the implementation-time floor, not a substitute.

## Not covered and why
- That the application's suite really passed: Soft Foundry never runs it (REQ-008). Review judges the recorded claim.
- Ignored or untracked files that alter behaviour but are not code paths: outside the tree hash, a recorded limitation (MIT-005).
- Real `my_ai` Rails repository: no access; the fixtures model its shape (shared core, auth paths) generically.
- Unscoped-path fail-closed git behaviour: unchanged on purpose (REQ-004), recorded as a finding.

## Run discipline
Run with provider keys unset (this machine exports them; see the local-env note) and run the full suite once before the pull request.
