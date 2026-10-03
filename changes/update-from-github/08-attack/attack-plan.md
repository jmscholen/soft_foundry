# Attack Plan

## Intent to challenge
That `update --yes` can be made to install only the gem of the release it found, and nothing else, whatever the network hands it.

## Threats mapped
ATTACK-001: THREAT-001. ATTACK-002: THREAT-001. ATTACK-003: THREAT-003.

## Adversarial journeys
For each ATTACK case record threat ID, attempted violation, starting privilege/state, steps, expected denial/safe behavior, observed result, and evidence. Recorded in `cases.yml`. ATTACK-001 and ATTACK-002 are the refusal tests and EVAL-003, with the network replaced or the real repository; ATTACK-003 is reasoned from the code and recorded as not run.

## Safety boundary
Production/third-party destructive or security testing requires explicit authorization. Only this checkout and the public repository's own source were used; nothing was published and nothing outside this machine was touched.
