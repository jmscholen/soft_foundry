# Security Review

## Scope reviewed

The version diff, the unchanged release path (`.github/workflows/release.yml`, `lib/soft_foundry/updater.rb`), and the verification checks, against `.ai/rules/security.md` and `.ai/rules/access-control-parity.md`. Attack is waived: the intake rationale is that this release adds no surface and `changes/gate-hardening` attacked the code it carries. This review did not re-run that attack. It looked for a new surface in the diff and found none.

`.ai/repository.yml` declares no `access_control` globs. The parity rule does not apply. No verification check needs `protection` or `protection_note`. The only changed application path is `lib/soft_foundry/version.rb`.

## Findings

None.

The diff is a string literal. It adds no input, credential, network call, path, or authorization decision. The release workflow's `contents: write` permission and `GH_TOKEN` use are unchanged and are what `gh release create` needs; the workflow file was not edited. The tag step refuses a tag that disagrees with `VERSION` (rehearsed: `v0.22.0` against `0.23.0` exited 1). The updater still installs only with `update --yes`, parses the asset name with `GEM_NAME`, and runs `gem` as an argument list. No secret-shaped string and no invisible character is in the diff or in this review's files.

The gemspec still has no license and no homepage. `gem build` warns and still writes the gem (`evidence/gem-build.txt`). That metadata predates this change. The intake forbids `gem push`, and the release path attaches the gem to a GitHub release.

## Conformance

Conforms to `.ai/rules/security.md`. `.ai/rules/access-control-parity.md` does not apply: the profile declares no `access_control` globs.
