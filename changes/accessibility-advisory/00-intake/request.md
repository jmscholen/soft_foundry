# Change Intake

## User intent
The maintainer asked for a review of Soft Foundry against accessibility standards and then said: "implement it all and make it an important gate, but report on the issues, don't make them a gate to advancing. Just notify on output of the issues that need to be addressed before it goes live."

The review found that the CLI's own output was in good shape (no color, no prompts, plain status words on `init`) but that the accessibility *process* was a template that had run once: seven of eight merged changes had skipped the review phase through `skipped_phases`, nothing in `.ai/` named a standard, the `surfaces.accessibility` flag was never read by code, and `doctor`/`check`/`ci`/`gate` conveyed pass/fail only through `✓`/`✗` glyphs.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-A11Y-001 (accessibility).** Every line `soft-foundry` prints that conveys an outcome carries a word (`pass`, `fail`, `warn`, `skip`, `error`, `warning`) next to any glyph, so the meaning survives stripping every non-ASCII character. Applies to `doctor`, `check`, `gate`, `change status`, `ci`, and the advisory lines themselves.
- **REQ-A11Y-002.** A named accessibility standard exists in the control plane: `.ai/rules/accessibility.md`, WCAG 2.2 Level AA for user interfaces plus rules for command-line output, documents, and the evidence each lifecycle phase owes. Review and specification skills reference it; the review template cites it.
- **REQ-A11Y-003.** `surfaces.accessibility` in a change's `metadata.yml` is read by code. `change new` sets it to `true` when `.ai/repository.yml` records a user-facing framework. With the flag true, the tool reports a missing accessibility requirement in the specification, missing accessibility observations in evaluation, and an accessibility review that is pending, skipped, TBD, or N/A. With the flag false in a repository whose profile records a user-facing framework, the tool says so.
- **REQ-A11Y-004.** Waiving the review or judge phase through `skipped_phases` is reported with the rationale given.
- **REQ-A11Y-005 (the maintainer's constraint).** All of the above are *advisories*: printed after the gate results by `gate`, `change status`, `ci`, and one last time by `change close`, each line starting with `! warn` and an area, under a heading that says they are informational. They never change an exit code and never block a phase or a close.
- **REQ-A11Y-006.** The maturity model requires an accessibility standard to be in force at level 5 (`accessibility.standard_in_force`); the deterministic scan scores it from file presence; this repository's profile records it.
- **REQ-A11Y-007.** `soft-foundry check` warns (never errors) when an installed control plane lacks the standard.

## Constraints
- Advisories must not fail anything: no exit-code change in `gate`, `status`, `ci`, or `close`, and no new gate check outcome of `:fail`.
- Existing change records must keep passing `ci` unchanged; the seven closed records that skipped review are history and are not rewritten.
- The `.ai/` directory is packaged and installed into other repositories, so the standard and the template edits ship with the gem automatically; nothing machine-local is written.
- Comments in `metadata.yml` must survive `change new`'s flag edit (a YAML round-trip would drop them).

## Non-goals
- Enforcing WCAG on any governed application automatically (no static analysis or browser audit is run by Soft Foundry).
- Restricting which phases `skipped_phases` may waive; the maintainer asked for reporting, not blocking.
- Rewriting the seven closed change records' accessibility reviews.
- ANSI color support with `NO_COLOR` handling; the CLI emits no color today and the standard records that as the rule.

## Task classification
Feature: a new rule file, a new `Advisory` module wired into four CLI commands, status words in four output paths, a `change new` behavior, a maturity capability with scan support, a `check` warning, template and documentation updates, tests.

## Initial risk
low. Output-only behavior plus one text edit to a file `change new` has just written; no new external interaction, credential, or network access; existing tests and change records continue to pass unchanged.
