# Mitigations

| ID | Threats | Mitigation | Where enforced | Verified by |
| --- | --- | --- | --- | --- |
| MIT-001 | THREAT-001 | The check contacts one fixed HTTPS address; downloads use only the URLs that release's JSON gives. | `Updater::LATEST_URI`, `#real_download` | `test_the_release_address_is_the_repository_on_github` |
| MIT-002 | THREAT-001 | The version requested must equal the release's; the file must be named `soft_foundry-<that version>.gem`; otherwise nothing is run. | `Updater#real_install` | `test_refuses_a_gem_whose_name_is_not_the_release`, `test_refuses_to_install_a_version_other_than_the_release_found`; ATTACK-001, ATTACK-002 |
| MIT-003 | THREAT-002 | Extraction into a fresh temporary directory removed afterwards; only a top-level directory with the gemspec is built. Path traversal inside the archive is left to `tar`'s own protections (modern `tar` strips leading `/` and refuses `..`). | `Updater#build_from_source` | accepted; see `08-attack/results.md` |
| MIT-004 | THREAT-003 | `Authorization` is sent only to hosts ending in github.com; at most five redirects; HTTPS only. | `Updater#real_download` | ATTACK-003 (reasoned; see results) |
| MIT-005 | THREAT-004 | The workflow fails unless `v<version>` equals the code's version, runs the tests, and only then builds and attaches the gem. | `.github/workflows/release.yml` | `test_a_tag_push_publishes_the_gem_as_a_release_asset` (shape); the first real tag |
