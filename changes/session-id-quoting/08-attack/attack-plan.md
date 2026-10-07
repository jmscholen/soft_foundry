# Attack Plan

## Intent to challenge
That a line written into the ledger by anything other than `record` can reach a printed command, or that a command built from a bad ID can run more than the agent.

## Threats mapped
THREAT-001 of changes/session-ledger (shell injection through a printed resume command), widened by REV-SEC-001 to a same-user writer of the ledger.

## Adversarial journeys
`cases.yml`, run by the real CLI against a scratch ledger.

## Safety boundary
Local, synthetic, throwaway directory; a stub `claude` on PATH stands in for the agent.
