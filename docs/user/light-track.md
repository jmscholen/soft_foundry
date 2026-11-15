# The light track

The light track is a shorter lifecycle for a change that does not need threat modeling, evaluation or attack. Changes to Soft Foundry itself use it.

## Create a change on it

```bash
git checkout -b change/<slug>
soft-foundry change new <slug> --track light
```

The track is recorded in `changes/<slug>/metadata.yml` as `track: light`. An unknown track name is refused, and the message lists the tracks `.ai/workflow.yml` defines.

## Which phases run

| Phase | On the light track |
| --- | --- |
| intake | required |
| specify | required |
| implement | required |
| verify | required |
| review | required |
| judge | required |
| discover, threat_model, plan | optional |
| evaluate, attack | optional |
| learn | optional |
| remediate, document, index, observe | optional, as on every track |

An optional phase may stay pending. The gate does not ask for it, `soft-foundry phase seal` steps over it to the next required phase, and `soft-foundry change close` does not wait for it. You may still run one: complete its handoff and seal it as usual.

## What stays the same

The light track removes phases. It does not remove locks.

- The specification is locked at the commit that seals it. A later edit fails the `specification locked` check.
- Each acceptance criterion carries a tier, the must list is capped by risk, and a person approves it before the specification seals.
- The remediation cap applies: a round beyond `remediation.max_rounds` needs a person's decision.
- Review and judgment are required and are never waived.

## Limits

- A change whose declared risk is high cannot be on the light track. The `track permitted` check fails and names the gated track.
- A change on the light track has no attack evidence. Judgment records attack as not run; it is not a pass.
- `track` is a line in `metadata.yml`. Someone with write access to the repository can edit it. That is outside what the gate checks.

## What `change status` shows

```text
c1: c1  [status: in_progress, phase: judge, risk: medium]
  track: light
  00-intake              complete     ok
  01-discovery           pending      optional on the light track
  02-specification       complete     ok
  03-threat-model        pending      optional on the light track
```

Each phase that did not run is labelled in words with the reason: optional on the track, optional on every track, waived in `skipped_phases`, or stepped over by default at low risk.

## Verification on a text-only change

When every path a change modified is documentation, the change's own record, or Markdown prose under `.ai/`, `soft-foundry change size --phase verify` reports the smaller verify size and gives "documentation-only diff" as the reason. Run `soft-foundry check` and `soft-foundry eval` as well; settings files under `.ai/` and harness evals are never counted as text.
