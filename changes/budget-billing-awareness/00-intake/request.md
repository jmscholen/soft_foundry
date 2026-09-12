# Change Intake

## User intent
The maintainer reported that "the budgeting is not working as intended." The existing mechanism (`budget-and-openrouter`: a policy cap plus a per-change ledger) applies uniformly, but how usage is paid for changes whether a dollar budget makes any sense:
- On a subscription plan there should be **no budget** at all: it is a flat fee with nothing metered per token.
- When usage runs on an API token, or `soft-foundry` itself is about to spend (its coding shells, its deep maturity assessment), there should be **a notification that a budget mechanism is in effect**, plus a **periodic warning every $10** of spend, with an option for the user to **adjust that warning threshold**.
- The budget mechanism itself must remain.

## Desired outcome
- Billing mode (subscription vs. API key) is detected from the machine's environment and stated plainly, with the reason, wherever spend is about to start or a change begins: `shell`, `init`/`onboard` (including `--maturity=deep`), `change new`, `budget status`.
- Subscription: the notice says no budget applies; `budget status` shows the ledger for reference only and never exits non-zero; `budget record` still records but says nothing budget-shaped.
- API key: the notice states the cap for the change's risk, the human-approval line, the warning interval, and the change's recorded spend so far; `budget record` warns each time the running total passes another multiple of the interval, announces the human-approval crossing, and exits non-zero over cap.
- The warning interval defaults to $10 in `.ai/policies/budget.yml` and is adjustable per machine (`soft-foundry budget threshold <usd|off|default>`), since how often to be nagged is a personal preference rather than repository policy.
- An environment override (`SOFT_FOUNDRY_BILLING=api|subscription`) corrects the detection when it is wrong for a particular setup.

## Constraints
- Soft Foundry still makes no real model completion calls itself, so the ledger remains the only thing that moves; a "periodic" warning can therefore only fire at `budget record` time, and the documentation says so rather than implying live metering.
- Detection must be per shell: an OpenAI key in the environment does not change how `claude` bills, so `shell claude` looks only at the variables Claude Code itself reads.
- Never print or persist a key's value; only whether it is set.
- Billing mode is a fact about the machine, not the repository, so it is detected at run time, not declared in `.ai/`.

## Non-goals
- Live interception or metering of real API calls (still needs a phase runner that makes them).
- Reading a coding shell's own cost reporting (e.g. Claude Code's `--output-format json` `total_cost_usd` from a `-p` run) into the ledger automatically. A natural next step for the deep maturity assessment, but out of scope here.
- A per-model pricing table.

## Task classification
Feature: a new billing-detection module, changes to the `budget` CLI subcommands, a new `budget threshold` subcommand, a billing notice at the spend entry points, one new policy field, and a README rewrite of the Budget section.

## Initial risk
low. Additive CLI behavior; the only new write is a machine-local, gitignored file; existing `budget status` semantics under an API key are unchanged (verified by the untouched pre-existing tests still passing).
