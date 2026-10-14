# Evaluation Plan

## Intent being proven
A person can run a real phase as a panel of two different agents and get two independent drafts, a recorded argument, an agreed consensus that cites both drafts and passes the gate, with each member's session narrowed by the guard.

## Personas
The maintainer with a hard specification question.

## Journeys
`journeys.yml`. One live panel: Claude Code 2.1.293 and Grok 1.0.30 on the specification phase of a scratch change ("where does the version number live"), run with the real CLI through a `PATH` shim, the guard installed in warn mode, and a logging hook recording the panel environment each hook process sees. The split path, forged agreement, and refusals are exercised by the attack phase and the tests; a live split was not forced.

## UI walkthrough evidence
N/A: the panel adds no page; its records reach the existing change page as files and advisories.

## Accessibility interaction
The `panel:` lines and `! warn panel:` lines carry status words; no prompts.
