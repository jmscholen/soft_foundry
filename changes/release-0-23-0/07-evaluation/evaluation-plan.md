# Evaluation Plan

Commit: 16bd5f7e0e036f0be98cad675b1c341f9f15d907 (the code is f6d6dc2; 16bd5f7 only adds the verification record).
Size: `full_route_sweep` (`soft-foundry change size --phase evaluate`; no scope declared, so whole repository). This product is a CLI, so a route is a command.

## Intent being proven
That a person can release 0.23.0 by the documented path and an adopter can then install and use it. The diff is one constant, so the risk sits in the path around it: nothing has run it for a real tag since v0.17.0.

## Personas
- Maintainer: opens the PR, tags, and watches the workflow.
- Adopter: holds 0.22.0 on their machine, runs `soft-foundry update --yes`, then uses the tool in their own repository.

## Journeys
Defined in `journeys.yml`. There are no acceptance criteria: the specify phase is waived, and `02-specification/acceptance-criteria.yml` is the unfilled template. Journeys therefore trace to the requirements REQ-REL-001 to 004 in `00-intake/request.md`. Placeholder AC-001 is not named by any journey, because no journey covers something that was never written.

## How the journeys run
All in scratch directories under the system temp directory, with a throwaway HOME and GEM_HOME, so the machine's gems and hooks are untouched. Nothing is pushed, tagged on the real repository, or published. `phase run` launches this session under `bundle exec`, so the leaked `BUNDLE_GEMFILE`, `RUBYOPT` and `SOFT_FOUNDRY_PHASE` are stripped by starting each command from an empty environment. The scripts are under `evidence/scripts/`.

Model-spending routes (`phase run` for real, `--panel`, `eval --live`) run as `--dry-run` or not at all. `shell claude` runs against a stub. The real release (EVAL-005) waits for the person's go-ahead and for judgment.

## UI walkthrough evidence
`soft-foundry ui` is unchanged by this diff. It is exercised over HTTP in EVAL-001 (token required on each API route). No browser walkthrough: no page changed.

## Accessibility interaction
N/A. `surfaces.accessibility` is false. The only thing a person perceives differently is the version number in `version`, the help header, and `update`.
