# Change Intake

## User intent
`soft-foundry` should have an `update` command for its own installed revision: check whether a newer version is published, and update to it.

## Desired outcome
- `soft-foundry update` checks RubyGems for the latest `soft_foundry` version and reports current vs. latest, writing nothing.
- `soft-foundry update --yes` installs the newer version if one exists.
- Nothing is installed without the explicit `--yes` step, since updating the tool's own installed binary is a consequential, hard-to-reverse action.

## Constraints
- This CLI has no interactive prompts anywhere; "confirm before touching anything" must follow the existing non-interactive idiom (a second explicit flag), not introduce stdin prompting as a first for this codebase.
- The check must never crash or hang on a network failure, an unpublished gem, or an unexpected API response; every failure mode is reported plainly with a clear exit code.

## Non-goals
- Auto-update, scheduled checks, or any check that runs without the operator invoking `update` directly.
- Rollback/downgrade support.
- Checking for updates as a side effect of other commands (`init`, `onboard`, etc.).

## Task classification
feature, application surface (one new library class, one new CLI subcommand).

## Initial risk
low. The check path is read-only against a public API. The install path shells out to `gem install` with a version string sourced from RubyGems' own response, not from user or repository input, and only runs when explicitly requested with `--yes`.
