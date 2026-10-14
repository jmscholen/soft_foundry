# Attack Plan

## Intent to challenge
THREAT-001 to THREAT-005 in `03-threat-model/threats.yml`.

## Threats mapped
ATTACK-002 THREAT-002 (guard narrowing); ATTACK-003 THREAT-004 (forged agreement, rewritten history); ATTACK-004 THREAT-003 and THREAT-005 (malformed requests, bounds); ATTACK-005 the implement refusal. ATTACK-001 (THREAT-001, inter-agent prompt injection) is reasoned and not run live: see results.

## Adversarial journeys
`cases.yml`, against the real CLI and the real guard command in a scratch repository; ATTACK-003 uses the CLI in process with stand-in agents.

## Safety boundary
Local scratch repository; synthetic data; no live agent was asked to attack.
