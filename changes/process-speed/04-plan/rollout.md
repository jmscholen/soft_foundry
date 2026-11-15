# Rollout

## Deployment ordering
1. Merge change/process-speed to main through a pull request after judgment.
2. Tag and release the next gem version (0.24.0) through the existing release workflow; never `gem push`.
3. The maintainer runs `soft-foundry update --yes` outside any bundle exec session and confirms the version.
4. New records get `rules: 2` from `change new`; in-flight records (readme-workflow-visuals, release-0-23-0) stay legacy.

## Migrations and backfills
None. Legacy records are never rewritten. A maintainer who wants an in-flight record under the new rules opens a new change for it.

## Feature flags and gradual exposure
The rules version is the flag: it applies per record from creation. The caps and default waivers are values in workflow.yml, adjustable without code.

## Success signals to watch
PC-001: the next real change under the new rules reaches judgment within two remediation rounds or parks with a clear decision. Number of remediate seals per change, from `git log --grep "^Record .* remediate$"`, falls back to two or fewer.
