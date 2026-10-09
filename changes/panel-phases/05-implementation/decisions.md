# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Agreement read from the bytes each member appended during its own turn | Parse `## member, round n` headings | A member can write any heading; the runner knows whose turn it was | A forged section under another name does not count; rewriting earlier text spoils the round |
| Members run one at a time in argument rounds, all at once in the independent round | All rounds in parallel | Each argument should answer the others' latest posts; independence needs no order | Argument rounds take longer in wall-clock time |
| The first member named writes the consensus | A separate writer session | The person controls it by order; that member already holds the debate in its session | A one-sided writer; the gate requires every draft cited |
| Split sets the handoff `blocked` and the change `awaiting_human` | Leave it to the consensus agent | A split is a decision for a person under the human-boundary policy | The change cannot advance until `human_decisions` records it |
| Guard narrowing through the session's environment | A panel lock file in the record | Hooks run as children of the shell and inherit its environment; nothing extra is written | Verified live for Claude Code in evaluation; under Grok in an untrusted folder the guard does not run at all |
| Codex members start a fresh session each stage | Look the session up in the ledger | Codex's `exec` cannot be handed an ID, and its later stages need only the files | A Codex member's argument is not informed by its own earlier reasoning beyond what it wrote down |
