# Assumptions

## Explicit assumptions
- "The agent should be able to do this" means the tool seals a phase (gate, then commit the phase directory and `metadata.yml`) and no person commits a phase by hand. It does not mean the agent may commit application code outside the implementation and remediation phases, and it does not remove the pull request as the person's merge decision.
- A phase's `commit_sha` continues to mean the HEAD the outputs describe, written by the agent before sealing. The sealing commit therefore comes after `commit_sha`, which is how every existing record already reads.
- Sealing commits only `changes/<slug>/<phase>/**` and `changes/<slug>/metadata.yml`. Application code is committed by the implementation or remediation session as today, before the phase is sealed.
- The pre-commit hook runs `soft-foundry ci`; a sealing commit must therefore pass `ci`, which is the intended effect, and a sealing command refuses before committing when the gate fails so the hook is never the first line of defence.
- The five closed-record YAML files that do not parse today (`changes/scoped-verification/02-specification/requirements.yml`, `07-evaluation/journeys.yml`, `06-verification/evidence/manifest.yml`; `changes/phase-lifecycle-controls/03-threat-model/threats.yml`; `changes/init-command/06-verification/previous/6df4d15e73d8/tests.yml`, an archived earlier run) are left as they are. Closed records are history; `change list` already states it does not re-gate them, and the new checks must behave the same way. Whether `ci` re-gates closed records today is a discovery question.
- The baseline test suite on `main` at `3e5627d` passes with provider keys and `SOFT_FOUNDRY_PHASE` unset. The run was started before this record existed and its result is recorded in the handoff findings when known.
- Harness-eval gate cases can express each new check (plant a defective record, name the check that must refuse it). The earlier finding that the gate-case format cannot assert a `check` release lint is about `check`, not `gate`, and does not apply here.
- The owed items from earlier changes are known from their judgment residual-risk files and from the maintainer's notes; discovery re-reads the records rather than trusting the notes.

## Ambiguities resolved
- **Which command seals a phase.** Not fixed at intake. The specification chooses between a new `soft-foundry phase complete <phase>` and a flag on `gate`; the intake requires only that it is one command, that it gates before it commits, and that `phase run` calls it.
- **What `--parallel` runs do.** Each parallel session is told not to commit today. Sealing happens in the runner after every session returns, one commit per phase, in lifecycle order. If one session fails, the phases that passed are still sealed and the failed one is left unsealed and reported.
- **Whether "predecessor complete" should require a commit.** Yes, from this change on. That is what makes sealing matter and what guarantees the specification lock and the plan diff base. The check's message names the sealing command so a session that forgot can recover without a person.
- **Fresh-session enforcement (item 9) versus agent autonomy.** Requiring a fresh session for review and judgment does not add a human step: `phase run` starts the session. The requirement only applies when the repository has chosen block mode, which this one has.
- **Scope of the parse check.** Required `.yml` files of a complete phase, plus `evidence/manifest.yml` where the phase has one. Markdown files are not parsed; their structure is the skill's responsibility.
- **Risk.** `high`, not `medium` as `small-process-fixes` was: that change added commands beside the gate; this one changes what the gate refuses.

## Ambiguities that block safe progress
None.
