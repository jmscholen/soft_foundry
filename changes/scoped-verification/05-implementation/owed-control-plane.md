# Control-Plane Files Owed (DEV-001)

Proposed contents for the files this phase may not write. Each matches what the code in `lib/soft_foundry/` already reads or checks.

## .ai/policies/check-sizing.yml
```yaml
# Check sizing, computed from the diff and the declared globs; never judged by hand.
# Names are listed smallest first. `soft-foundry change size` prints the computed
# size and the paths that caused it; the verification gate refuses a recorded
# size smaller than the computed one.
#
# verify: the smaller size only when the record declares a scope and every
#   changed code path is inside it (none in the shared core, none outside it).
# evaluate, attack: the smaller size only when the record declares a scope, the
#   repository declares access_control globs, and no changed path matches them.
# Absence of a declaration never reduces checking.
sizes:
  verify: [targeted_plus_full_before_merge, full_at_verify]
  evaluate: [touched_doors_plus_smoke, full_route_sweep]
  attack: [touched_doors_plus_smoke, full_route_sweep]
```

## .ai/templates/change/metadata.yml
Add after `track:`/`status:` lines:
```yaml
scope: []                  # optional path globs this change owns; empty is whole-repository. Evidence is stale only for changes that matter to it (.ai/policies/check-sizing.yml)
```

## .ai/skills/verification/template/tests.yml
Add at the top level, after `commit_sha:`:
```yaml
# Optional. The check size computed by `soft-foundry change size --phase verify`.
# A scoped change must record a size at least as large as the computed one.
# size: TBD
# Optional full-suite run, keyed by the git tree hash of the evidence commit
# (`git rev-parse <commit_sha>^{tree}`), or a citation of another record's run
# for the same tree. This is a record: Soft Foundry never runs the suite.
# full_suite:
#   tree: TBD
#   command: TBD
#   outcome: passed
# full_suite:
#   cite: <slug of another change record>
```

## SKILL.md additions (verification, evaluation, adversarial-testing)
One sentence each: "Run `soft-foundry change size --phase verify` (evaluate, attack) and do the checks it names; record the size in `tests.yml`." Verification also: "When the size is `full_at_verify`, or before merge for `targeted_plus_full_before_merge`, run the full suite and record it under `full_suite:` or cite a record that ran it on the same tree."

## .ai/workflow.yml
Under `rules:`, name `.ai/policies/check-sizing.yml` as the sizing policy.

## Documents (`.ai/README.md`, `.ai/schemas.md`, `README.md`)
Document `scope` (metadata.yml), `shared_core` and `access_control` (`.ai/repository.yml`), the `size` and `full_suite` fields of the verification record, `change size`, `change new --scope`, and the sizing policy. Include this sentence: "A passing full-suite check shows that a recorded run names this tree with a recorded outcome, not that the suite passed; Soft Foundry never runs the application's tests."

## Harness-eval cases (`.ai/harness-evals/cases/`)
Gate cases that plant: a scoped record with a change in scope (stale), a change claimed by another active record (current), a shared-core change (stale for both), a narrowed scope after the evidence (stale, declaration changed), and a full-suite record naming a different tree (check fails). The case format is in the existing cases, which this phase may not read.
