# Verification
Run deterministic engineering gates: tests, linters, static analysis, security scanners, IaC validation, migrations/checks, and other repository-defined checks. Report failures; do not repair code or rewrite tests to obtain a pass.

Where implementation committed a failing test before the code (`.ai/rules/testing.md`), record that commit as `red_commit` and the test file as `test_path` on the check that runs it in `tests.yml`. Do not name a commit you have not confirmed contains the test; the gate checks the commit's shape, not the test's result there.


This phase prefers a fresh session: `soft-foundry phase run verify` starts one with only this skill in its prompt and records `executed_by` in the handoff; a verification completed by the session that implemented the change is advised on every gate run.
