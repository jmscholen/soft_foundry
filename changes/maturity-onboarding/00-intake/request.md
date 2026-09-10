# Change Intake

## User intent
`soft-foundry onboard` (and `init`, which calls it) should evaluate the repository's maturity model against `.ai/maturity.yml`, writing the result to `.ai/repository.yml`. If a repository is already assessed, later onboarding runs skip re-assessing it.

## Desired outcome
- A `--maturity=scan|deep|off` flag on `onboard` and `init`, `scan` as the free/default mode, `deep` an opt-in agentic mode, `off` today's behavior.
- `scan`: deterministic, offline, detects technology/testing/infrastructure from file presence and scores only the maturity capabilities that presence can honestly answer.
- `deep`: shells into an installed `claude` CLI to run the real `repository-discovery` skill with actual judgment, for repositories willing to spend on a fuller assessment.
- Regardless of mode, a repository already marked `assessed: true` in `.ai/repository.yml` is skipped on later onboarding runs, with a `--reassess` flag to force a fresh run.
- Maturity assessment must not be gated by `--no-onboard`: that flag concerns provider discovery (a network operation), and `scan` mode has nothing to do with the network.

## Constraints
- `scan` mode must never invent a capability status it cannot support; `.ai/maturity.yml`'s own assessment_rules (UNKNOWN unless absence is established, NOT_APPLICABLE only with rationale) apply exactly the same to deterministic detection as to agentic judgment.
- `deep` mode must never bypass permission prompts or run with elevated flags; a failure must be reported plainly and must never block the rest of `init`/`onboard` from completing.
- The one file `deep` mode's agent writes outside a change context (`.ai/repository.yml`) is already an explicit exception in `repository-discovery`'s own `permissions.yml`; this change does not grant any new privilege.

## Non-goals
- Reaching maturity levels 3 and above from a fresh scan: those require proof that changes actually went through the lifecycle, which no file-presence scan of an unstarted repository can manufacture.
- A pricing/cost estimate for `deep` mode.
- Changing `repository-discovery`'s own permissions or the change-record-scoped discovery phase; this is a separate, standalone entry point for assessing the repository outside any specific change.

## Task classification
feature, application surface (CLI, two new library classes, control-plane scoring logic).

## Initial risk
low-to-medium. `scan` mode is read-only against the target plus one guarded write, the same risk class as `init-command`'s already-hardened writes. `deep` mode introduces a genuinely new surface, shelling out to an external binary, so it received explicit threat consideration inline (see `05-implementation/log.md`) even though the full adversarial-testing phase was not run for this change.
