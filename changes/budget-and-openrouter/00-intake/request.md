# Change Intake

## User intent
Add a budget constraint mechanism, since model API usage could get expensive, and add OpenRouter as a provider option.

## Desired outcome
- A declared budget policy (spend caps) and a per-change ledger the harness or a human can record spend into and check against the cap.
- Exceeding a change's cap is treated as a financial commitment under the existing human-boundaries policy, not silently allowed.
- OpenRouter is discoverable the same way OpenAI, Anthropic, and xAI already are: an environment variable, a `/models` listing, inclusion in `soft-foundry models` output.

## Constraints
- Soft Foundry does not currently make any real model completion calls itself (only read-only model-listing for discovery); a budget mechanism built today is necessarily policy plus a ledger, not live metering. This is stated plainly rather than oversold.
- Reuse the existing human-boundaries policy for the "over cap" consequence rather than inventing a parallel approval mechanism.

## Non-goals
- Live interception/metering of real API calls (needs a phase runner that makes them, which doesn't exist yet).
- A hardcoded per-model pricing table; `--usd` is supplied by whoever records the entry.
- Profile-to-model routing that prefers OpenRouter for cost reasons (the profile resolution mechanism itself is still unbuilt; OpenRouter becomes a provider, not a routing policy).

## Task classification
feature, application surface (CLI, control-plane policy, change-record scaffolding).

## Initial risk
low. No filesystem writes into arbitrary target-repo paths beyond the ordinary `change new` scaffolding already covered by `init-command`'s adversarial testing; new surface is a discovery-only HTTP provider entry (mirrors three existing ones) and a YAML ledger read/write scoped to the change's own directory.
