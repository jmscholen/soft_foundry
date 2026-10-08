# Attack Plan

## Intent to challenge
That a hook payload, a prompt, a folder or repository, or the file system around the ledger can make Soft Foundry run a command, leak a secret, write somewhere else, stall prompts, lose entries, or let a Grok tool call past the guard.

## Threats mapped
THREAT-001 to THREAT-009 from `03-threat-model/threats.yml`, one or more cases each (THREAT-009 as ATTACK-008).

## Adversarial journeys
`cases.yml`, run by the script recorded in `evidence/attack-transcript.log` against the real CLI executable as separate processes, in a throwaway directory with synthetic data.

## Safety boundary
Local only, synthetic data, nothing written outside the throwaway directory; no network; no agent configuration in the real home directory touched. Production and third-party testing: not applicable.
