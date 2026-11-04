# Change Intake

## User intent
Bump the Soft Foundry version and release it, so the gate-hardening work merged in PR #57 can be installed in other repositories. The person asked for "version bump and release" on 2026-11-04.

## Desired outcome
- REQ-REL-001: `lib/soft_foundry/version.rb` says 0.23.0.
- REQ-REL-002: the change merges to main through a pull request.
- REQ-REL-003: tag `v0.23.0` on the merged commit produces a GitHub release with `soft_foundry-0.23.0.gem` attached, through `.github/workflows/release.yml`.
- REQ-REL-004: `soft-foundry update --yes` installs 0.23.0, and the installed gem contains `lib/soft_foundry/phase_seal.rb`.

## Constraints
- Never `gem push`; the gem is not published to RubyGems.
- No behaviour change: the version constant is the only application edit.
- Pushing the branch, merging, and pushing the tag are outward-facing and are done with the person's go-ahead.

## Non-goals
- Scoped pre-commit hook, freezing finished records, a guard refusal of `--no-verify`, and any `my_ai` cleanup.
- Tagging the skipped versions 0.18 through 0.22.

## Task classification
chore: a release of code that is already merged and judged.

## Initial risk
low: one constant changes. What the release carries was judged in `changes/gate-hardening`. The real risk is outside the diff: the tag path has not run since v0.17.0, which REQ-REL-003 and REQ-REL-004 exercise.
