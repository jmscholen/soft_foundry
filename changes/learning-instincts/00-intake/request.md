# Change Intake

## User intent
Fourth of the five additions from the ECC evaluation, agreed with "ok, lets do the 5 recommended additions": a learning output with confidence. The learning phase has templates for findings, proposed rules, and proposed evals, but no record in this repository has ever completed it, and the maturity profile has recorded `learning.feedback_loop: MISSING` (`no_governance_path_for_proposed_rule_changes`) since discovery. ECC's instincts are the right unit: one trigger, one action, one confidence score, one evidence pointer. The governance path is what Soft Foundry adds: a lesson reaches the rules through a later change's record, never by the change that learned it.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-LRN-001.** The learning skill requires `15-learning/instincts.yml`, scaffolded from a template with `instincts: []` and a commented example. Each instinct has a kebab-case `id`, a `trigger`, an `action`, a `confidence` between 0 and 1, an optional `domain`, and non-empty `evidence` naming a finding, phase, or path in the record.
- **REQ-LRN-002.** The learning gate carries an `instincts valid` check: it fails naming each malformed entry's problem (id, duplicate, trigger, action, confidence, evidence) and invalid YAML; it passes counting the instincts by id, and passes an empty list as "no instincts recorded".
- **REQ-LRN-003.** `soft-foundry learn list [--min-confidence X]` prints every valid instinct from every record, closed ones included, highest confidence first, as `<confidence> <change> <id> (<trigger>; <action>)`.
- **REQ-LRN-004.** `soft-foundry learn promote [--min-confidence X] [--dry-run]` copies instincts at or above the threshold into `.ai/rules/learned.md` as sections headed by id with the trigger, the action, the confidence, the change that learned it, its domain, and its evidence; skips instincts already present (by heading) and those below the threshold, saying which; `--dry-run` prints what it would promote and writes nothing.
- **REQ-LRN-005.** `learn promote` refuses when the current branch has no change record or the record is closed, saying that a promotion is a change to `.ai/rules` and goes through a change record; it names the record it went through when it writes.
- **REQ-LRN-006.** The threshold is `promote.min_confidence` in `.ai/policies/learning.yml` (`0.8` shipped); `--min-confidence` overrides it for one run.
- **REQ-LRN-007.** `.ai/rules/learned.md` exists with a header and is a baseline rule for the implementation and exploration skills; `.ai/rules/README.md`, `README.md`, `.ai/schemas.md`, and the learning skill's `SKILL.md` document instincts, the gate, `learn list`, and `learn promote`.
- **REQ-LRN-008.** This repository's profile records `learning.finding_capture`, `learning.feedback_loop`, and `learning.standards_feedback` as PASS with the maturity rules that say why, keeps `learning.regression_creation` MISSING with its finding named, and the version is 0.13.0. This change completes its own learning phase with instincts from this series, the first record to do so.

## Constraints
- Promotion writes only `.ai/rules/learned.md`, through `SafeWrite`, and only on a branch with an open change record.
- Every line `learn` prints carries its outcome as a word per `.ai/rules/accessibility.md`.
- Existing records are unaffected: their learning phases are pending or skipped, and the new required file only matters when the phase completes.

## Non-goals
- Automatic promotion. A person runs `learn promote` inside a change; the tool never applies a lesson on its own.
- Merging or retiring instincts. `learned.md` grows; pruning is an edit through a change record, like any rule change.
- Turning findings into regression tests (`learning.regression_creation`), which stays MISSING and named.

## Task classification
Feature: a `Learning` module, a gate check, two `learn` subcommands, a template and completion change, a policy file, a rules file, baseline-rule entries, documentation, profile and maturity updates, tests, this change's own learning phase, and the change's own RED commit.

## Initial risk
low. One new file under `.ai/rules/` written only through a change record; read-only gate checks; an advisory-free change (nothing new reports). Existing tests and change records pass unchanged.
