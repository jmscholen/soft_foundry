# Assumptions

## Explicit assumptions
- Performed directly by the interactive session that implemented the change, not by fresh-context agents per phase; the review and attack are not independent, and the advisory says so for review.
- The repository is public, so the releases API needs no token; one is sent when `GITHUB_TOKEN` is set, for rate limits or a later private repository.
- A release is made by pushing a tag `v<version>`; the workflow builds and attaches the gem. Until the first such tag exists, `update` reports that no release has been published.
- "The local installation where it's installed in a repo of another application" is read as the gem the `soft-foundry` command on PATH runs, which is one installation per Ruby on the machine, plus the `.ai/` that `init` wrote into that repository. `update` replaces the first and points at `init` for the second.
- Evaluation of the install path used the real network against the repository's `main` source tarball, since no release existed; the attached-gem path is exercised with the network replaced, and for real only after the first tag.

## Ambiguities resolved
- Why a tarball fallback: a release made by hand in the GitHub interface has no gem attached; building the tagged source gives the same gem the workflow would.
- Why `RbConfig.ruby -S gem` rather than `gem`: the `gem` on PATH may belong to another Ruby than the one running the command; the install must land where `soft-foundry` runs.

## Ambiguities that block safe progress
None.
