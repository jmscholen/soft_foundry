# Remediation

## Finding references
- **REM-001, from 06-verification (notes and results.md) and from the orchestrating session.** With the guard in block mode (REQ-FR-004), the fresh-context verification session could not run the test suite or the tool from the shell: the guard refused every shell command naming `exe/` or `test/`, because the verification skill lists `${APP}` and `${TESTS}` in `deny_write` and a shell command was checked against the deny sets by name alone. The session worked round it with a script outside the repository. The orchestrating session then hit the same refusal trying to launch `phase run evaluate` (naming `exe/soft-foundry`) and even to `cat` a skill's `permissions.yml` (naming `.ai/`), and found a second limit: `phase run` refused to rerun a complete phase even after its evidence had gone stale, so a remediation could not be re-verified without editing the verification handoff, which the remediation skill may not touch. In warn mode nobody had noticed either; block mode made both visible on the first run.

## Root cause
- The shell rule conflated "may not write" with "may not name". An evidence skill reads `${APP}`, `${TESTS}`, and `${CONTROL_PLANE}` by permission, and running tests, the tool, or `git diff` over them is reading, not writing; refusing the names made every evidence phase impossible to perform under block mode without going round the guard, which is the opposite of what block mode is for.
- `PhaseRunner#refusal` treated `complete` as final, although the gate already knows when a complete phase is stale.

## Changes made
- RED `d5940c2`: `GuardShellNamingTest` (verification may name `test/`, `exe/`, and `.ai/rules/` in a shell command; may not name harness evals, `.ai/policies/`, or the guard's own configuration; implementation may name the rules it reads and not `.ai/policies/`; a stale complete phase is not refused by `phase run`).
- GREEN (the commit this handoff names): `Guard#decide_by_skill`, shell branch: a command is refused when it names the guard's own configuration, protected policy or harness material (`.ai/policies/skill-permissions.yml` `protected:`), a `deny_read` path, or a `deny_write` path the skill may not read; a `deny_write` path the skill may read is allowed. `PhaseRunner#refusal` allows a complete phase whose gate reports `evidence current` failing. `test/guard_test.rb`: the `rm -rf .ai/policies` expectation reads the new reason.
- Requirement effect: REQ-FR-004 is unchanged (block is the default; the override order is unchanged; the guard still protects its configuration). The guard is narrower only in that naming a readable path from the shell is no longer a violation; a shell write to such a path is caught by the gate's staleness check and by review, as the guard's own limit (it cannot know what a command writes) always implied.

## Documentation owed, outside every skill's write set
The README paragraph that says the guard "refuses a command that names a denied path and passes everything else" and the comment at the top of `.ai/policies/enforcement.yml` saying the same must read: a shell command may name what the skill may read; it is refused when it names a path the skill may not read, a `deny_write` path the skill may not read, protected policy or harness material, or the guard's own configuration. This session cannot write `README.md` or `.ai/policies/` under the remediation skill, and in block mode it cannot create the machine-local override from inside the session (the guard refuses writes to its own configuration, as REQ-FR-004 requires). The maintainer applies these two text edits at merge, under the documented override on their own machine. Listed here so review and judgment carry it.

## Evidence invalidated
Verification at `776b640` (the guard and runner code changed after it).

## Required reruns
Verification, evaluation, and attack, all at the remediated commit, each through `soft-foundry phase run` in a fresh session; the gate reports verification stale until then, and `phase run verify` now accepts the rerun.
