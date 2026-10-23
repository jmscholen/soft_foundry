# Rollback

## Trigger conditions
- Any case where scoped staleness lets evidence pass that the previous rule would have staled, and the cause is the code rather than a wrong declaration.
- Existing records or repositories change behaviour without new declarations (a REQ-004 violation).
- Gate or `check` failing on existing repositories because of new checks.
- A git call count that grows with changed files.

## Procedure
1. Fastest per-repository mitigation, no code change: remove `scope:` from records and `shared_core`/`access_control` from the profile; behaviour returns to the legacy rule (declarations are the only opt-in).
2. Code rollback: revert the merge commit of the change branch (the change is additive and self-contained), rebuild the gem locally and reinstall the previous version under the asdf Ruby. Never `gem push`.
3. Records already carrying `full_suite` or `size` fields remain readable: the previous version ignores unknown keys. Re-run `soft-foundry gate verification` on affected records with the previous version; evidence that cited a run is re-gated and, if the previous gate has no such check, it simply does not apply.
4. Per `workflow.yml` transitions, a blocking review finding or a BLOCKED judgment returns the change to verify; evidence recorded under the faulty rule is considered untrusted and re-run.

## Data considerations
No stored data or migration. New optional YAML fields only; the policy file and templates revert with the commit. Citations between records refer to tests.yml in other records and stay as inert text after revert.

## Time to recover
Minutes for the declaration-removal mitigation; under an hour for a revert, rebuild and local reinstall. No external service is involved.
