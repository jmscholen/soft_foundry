# Assumptions

## Explicit assumptions
- "Vetted between the user and the agent" is a person's act, so it is a command a person runs (`change vet`) that records who and at which commit, not a state an agent may set by editing metadata. The gate then holds the record to it.
- "Deploy to a development environment" is a fact about the governed repository, so it lives in `.ai/repository.yml` under `environments:` and is a human boundary everywhere else. Soft Foundry records where the feature was put in front of a person; it does not deploy.
- The exploring stage produces no evidence. Its output is a journal (`exploration/iterations.yml`) and a living draft specification. This is what makes the stage cheap and what keeps the hardening phases meaningful, so it is linted (`check` refuses a stage skill that can write commit-bound evidence) and gated (`not exploring`).
- The hardening phases begin at `implement`. Intake and the specification are what a vet locks; discover, threat_model, and plan are what the iterative track makes optional, because a feature shaped by trying it has already been discovered and planned in the journal. A high risk change does not get that option.
- Both tracks share one phase list and one gate. A track changes which phases must precede implementation, whether an exploring stage exists, and when the specification locks; it does not add or remove gate semantics elsewhere.
- Given this change's low risk and the maintainer's established process for repository-native changes, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by prior changes, on the gated track (the default), and the review phase is run for it because the change alters what the lifecycle requires. That choice is recorded here rather than silently assumed.

## Ambiguities resolved
- Whether `current_phase` should be a new value while exploring: no. It stays a lifecycle id (`implement`, the phase whose directory the stage also writes) and `status: exploring` is what selects the stage skill; `AGENTS.md` says so.
- Whether `reopen` may rewrite phase handoffs, given the anti-fudging rule against altering another phase's evidence: yes, as a recorded transition a person initiates. Files stay in place, a note is appended naming the reopening, and the reopening is kept in `metadata.yml`. Leaving the handoffs `complete` would fail the gate on the next commit and force a hand edit, which is worse.
- Whether the vet should require the journal to be committed too: no. The journal is not locked; it keeps growing if the change is reopened. The vet requires the intake and the specification to be committed because those are what the vetted commit locks.
- Whether `vet` should refuse when the repository records no development environment: no. A library (this repository) explores by other means and says so in the journal; the gap is advised, never a refusal.
- Whether the gated track should also gain a deterministic specification lock: not in this change. Its specification handoff records HEAD at production time, before the record itself is committed, so there is no commit to lock at without changing how gated records are written.

## Ambiguities that block safe progress
None.
