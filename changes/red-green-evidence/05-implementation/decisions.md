# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Verify the shape of the RED claim, not the test's result at RED | Check out `red_commit` in a worktree and run the test | The gate does not know the repository's test runner and must stay fast and read-only; a person can reproduce the claim from the commit | Documented as the check's limit in README, schemas, and the verification skill |
| Require an `APP` or `INFRA` change between RED and GREEN | Any change; a `TESTS` change too | "GREEN" means the implementation happened; a RED followed by docs or more tests is not that | A `TESTS`-only follow-up cannot be passed off as GREEN |
| `red_commit` is optional and advised, never required | Required for features | The maintainer's standing rule for this family of checks; characterisation tests written after the fact are legitimate and the advisory makes them visible | Existing records pass the gate unchanged; open feature records get the advisory |
| The advisory covers `feature`, `fix`, and `refactor` | Every type | A docs, chore, or security-policy change has nothing to fail first | `RED_EVIDENCE_TYPES` constant |
| Invalid `tests.yml` YAML fails the `red evidence` check | Let the placeholder check catch it | This check is the one that reads the file as data; the placeholder check reads text | The evaluation's accidental first run exercised exactly this path |
| Ancestry by `merge-base --is-ancestor` | Same-branch linear history | A RED commit merged from another branch is still evidence if the verified commit descends from it | The elsewhere-branch test covers the negative |
| Do this change test-first and cite its own RED commit | Implement, then write tests | The change's record should carry the evidence it introduces, or the feature is unproven on the repository that ships it | `tests.yml` names `5d898e0`; `red-at-5d898e0.log` is the run at that commit |
