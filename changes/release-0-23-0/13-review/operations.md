# Operations Review

## Scope reviewed

What an operator does to ship and roll back 0.23.0: `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `lib/soft_foundry/updater.rb`, `README.md` Updating, and the pending `12-observability/` scaffold. `surfaces.observability` is false. No service, dashboard, alarm, or metric was added. `.ai/rules/observability.md` and `.ai/rules/errors.md` apply to new failure modes; this diff adds none in the library.

## Findings

None beyond REV-001 and REV-002, which are recorded in `functional.md`.

The pull-request failure mode is detected: `rake ci` exits 2 when handoffs are missing (REV-001). The tag failure mode is detected: the workflow exits 1 when the tag disagrees with `VERSION`, and the rehearsal showed that line. A bad asset name is detected by the updater, which accepts only `soft_foundry-<version>.gem`.

Rollback of a tag that has not been pushed is to stop. Rollback after a GitHub release is a human action (delete or supersede the release); this change does not add a down-grade path, and the rehearsal showed `update` on 0.23.0 refusing to move down to `v0.17.0`. There is no migration.

`10-user-documentation/`, `11-faq-index/`, and `12-observability/` are still the pending scaffolds. README already documents `soft-foundry update` and `update --yes`. No user document hard-codes 0.22.0. Leaving those optional phases pending matches a one-constant change, provided their directories are in the commit that is pushed (REV-001).

## Conformance

Conforms to `.ai/rules/observability.md` and `.ai/rules/errors.md` for the diff. The release's remaining operational work is REV-001 before the pull request and REV-002 at tag and update time.
