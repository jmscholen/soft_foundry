# Attack Plan

## Intent to challenge
That nothing is read without the token, that the token cannot be supplied or obtained by another origin, that a request cannot choose what directory is read, and that repositories the user did not choose cannot inject into the page.

## Threats mapped
ATTACK-001: THREAT-002. ATTACK-002: THREAT-003. ATTACK-003: THREAT-001. ATTACK-004: THREAT-004. ATTACK-005: REQ-REPO-007. THREAT-005 and THREAT-006 are accepted and have no case.

## Adversarial journeys
For each ATTACK case record threat ID, attempted violation, starting privilege/state, steps, expected denial/safe behavior, observed result, and evidence. Recorded in `cases.yml`.

## Safety boundary
Production/third-party destructive or security testing requires explicit authorization. Everything here targeted a server this session started on loopback and scratch repositories it created. The maintainer's own repositories were listed by the server and are not named in the evidence; none of their files was written.
