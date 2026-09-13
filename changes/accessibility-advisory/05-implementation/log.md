# Implementation Log

## Changes made
- `.ai/rules/accessibility.md` (new): the standard. WCAG 2.2 AA applied rules for user interfaces with success-criterion numbers; command-line and log output rules (a word for every outcome, no color unless a TTY without `NO_COLOR`, line-oriented, no prompts, plain-language errors); document rules; the evidence each lifecycle phase owes.
- `lib/soft_foundry/advisory.rb` (new): `SoftFoundry::Advisory` computes go-live notices for a change record: review/judge waived through `skipped_phases`; with `surfaces.accessibility: true`, a specification without a `category: accessibility` requirement (or skipped), evaluation results with empty/TBD/N/A accessibility observations, and an accessibility review that is pending, skipped, TBD, or N/A; with the flag false in a repository whose profile records a user-facing framework, a prompt to confirm; and a missing `.ai/rules/accessibility.md`.
- `lib/soft_foundry/cli.rb`: status words on every outcome line (`✓ pass`, `✗ fail`, `! warn`, `- skip`, `✗ error`, `! warning`); `print_advisories` after gate results in `gate`, `change status`, `ci` (open records), and before `change close` closes.
- `lib/soft_foundry/change_record.rb`: `change new` sets `surfaces.accessibility: true` by a one-line text edit when `.ai/repository.yml` records a user-facing framework, preserving the template's comments.
- `lib/soft_foundry/control_plane.rb`: `repository_profile` reads `.ai/repository.yml` once.
- `lib/soft_foundry/maturity_scan.rb`: scores `accessibility.standard_in_force` from the presence of the rule file (PASS / UNKNOWN).
- `lib/soft_foundry/check.rb`: warning when the standard is absent from an installed plane.
- `.ai/maturity.yml`: `accessibility.standard_in_force` required at level 5, with an assessment rule. `.ai/repository.yml`: this repository records it PASS.
- `.ai/templates/change/metadata.yml`, `.ai/skills/review/SKILL.md`, `.ai/skills/review/template/accessibility.md`, `.ai/skills/specification/SKILL.md`, `.ai/skills/evaluation/template/evaluation-plan.md`, `.ai/rules/README.md`, `.ai/schemas.md`, `AGENTS.md`, `README.md`: the flag's meaning, the standard's applicability, the advisory semantics.
- Tests: `test/advisory_test.rb` (advisory rules, CLI wiring, `change new` flag, status words, ASCII-stripped output), additions to `test/maturity_scoring_test.rb` and `test/maturity_scan_test.rb`.
- Version bumped to 0.7.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- A governance flag nobody reads is worse than no flag: every record had `accessibility: false` including the one change that actually had an accessibility requirement. Wiring the flag to output made the inconsistency visible immediately.
- "Report, don't block" needs its own output channel with its own stable prefix (`advisory:`, `! warn <area>:`), or it disappears into the gate's pass/fail lines and gets ignored or mistaken for a failure.
- The framework list in the repository profile is preserved in profile order, not sorted; anything printed from it has to sort first or tests become order-dependent.

## Challenges
None substantive.
