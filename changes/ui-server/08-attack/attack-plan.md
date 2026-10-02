# Attack Plan

## Intent to challenge
That the server discloses nothing beyond its six routes to anything but the viewer's own page, changes nothing, cannot be made unusable cheaply, and that a hostile record cannot run script in the page.

## Threats mapped
ATTACK-001: THREAT-003. ATTACK-002: THREAT-001. ATTACK-003: THREAT-002. ATTACK-004: THREAT-005. ATTACK-005: THREAT-006. ATTACK-006: THREAT-006, THREAT-010. ATTACK-007: THREAT-004. ATTACK-008: THREAT-009. ATTACK-009: THREAT-007. THREAT-008 is accepted and has no case.

## Adversarial journeys
For each ATTACK case record threat ID, attempted violation, starting privilege/state, steps, expected denial/safe behavior, observed result, and evidence. Recorded in `cases.yml`. The cases were run twice: at `93b9422`, where ATTACK-005 succeeded and ATTACK-008 showed a defect, and at the remediated commit, where all are denied.

## Safety boundary
Production/third-party destructive or security testing requires explicit authorization. Everything here targeted a server started for the purpose on 127.0.0.1, serving a throwaway repository, on the maintainer's own machine. Nothing third-party and nothing destructive.
