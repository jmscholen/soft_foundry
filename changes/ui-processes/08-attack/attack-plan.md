# Attack Plan

## Intent to challenge
That the listing repeats nothing a process put in its command line beyond validated fields, cannot be made to run anything, obeys the server's refusals, and does not disturb what it lists.

## Threats mapped
ATTACK-001: THREAT-001. ATTACK-002: THREAT-002, THREAT-003. ATTACK-003: THREAT-002. ATTACK-004: THREAT-001, THREAT-004.

## Adversarial journeys
For each ATTACK case record threat ID, attempted violation, starting privilege/state, steps, expected denial/safe behavior, observed result, and evidence. Recorded in `cases.yml`.

## Safety boundary
Production/third-party destructive or security testing requires explicit authorization. Everything here ran against processes this session started in scratch directories on the maintainer's machine, and a server it started on loopback. The maintainer's own running `ui` server was listed, and was not signalled or contacted.
