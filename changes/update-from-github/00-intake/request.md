# Change Intake

## User intent
"I dont want to ship this to ruby gems community." Then: "lets fix that issue. I want the update command to pull down the latest github repo release and update the local installation where its installed in a repo of another application."

## Desired outcome
- REQ-UPD-001: `soft-foundry update` reads the latest release of github.com/jmscholen/soft_foundry, not RubyGems. With no release it says so, with the releases page's address, and exits 1.
- REQ-UPD-002: `soft-foundry update --yes` installs exactly the release found: the `soft_foundry-<version>.gem` attached to it, or, when none is attached, the gem built from the release's tagged source. It installs under the Ruby that runs `soft-foundry`, so the command on PATH is updated from whatever repository it is run in. Nothing runs through a shell; a file whose name is not `soft_foundry-<version>.gem` for that version is refused.
- REQ-UPD-003: a tag `v<version>` pushed to the repository becomes a GitHub release with the built gem attached, by a workflow that refuses a tag that does not match `lib/soft_foundry/version.rb` and runs the tests first.
- REQ-UPD-004: after installing, if the repository the command was run in has a `.ai/` written by an older version, the command says so and names `soft-foundry init` as the way to bring it forward.
- REQ-UPD-005: `.ai/repository.yml` records the deployment target as GitHub releases, not RubyGems.
- REQ-UPD-006 (accessibility): every message is a line in words with what to do next; no prompt; `--yes` remains the explicit second step.

## Constraints
- No new dependency: `net/http`, `json`, `tmpdir`, `rbconfig`, `open3` are standard library; `tar` and `gem` are already required by the environment.
- `.ai/rules/security.md`: what is downloaded is code that will be installed. HTTPS only; the version asked for, the version the release names, and the version in the file's name must agree; argument lists, never a shell.
- Never `gem push`.

## Non-goals
- Signing or checksumming releases beyond GitHub's own TLS and the name checks; a later change may add a checksum to the release.
- Updating a repository's `.ai/` as part of `update`; that stays `init`'s job and is pointed to.
- Private repositories: a `GITHUB_TOKEN` in the environment is sent if present, but nothing here manages one.
- Downgrades or pinning a version.

## Task classification
feature

## Initial risk
medium. The command downloads and installs code. Contained by HTTPS to github.com, a fixed repository address, and three agreeing version checks; threat-modelled in this record.
