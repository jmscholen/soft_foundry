# Remediation
Repair findings from verification, evaluation, attack, or review without altering their evidence or expected outcomes. Record root cause and remediation. After any implementation change, downstream validation evidence becomes stale and applicable stages must rerun.

Fix what blocks: unmet must criteria, and blocking and major findings that name a failure. Carry minor findings forward in the summary instead of rewriting text that then needs checking again; every rewritten sentence is a new claim. Fix the smallest thing that resolves the finding: narrow or remove a claim rather than add a qualified one. A finding marked `outside_change` belongs to its follow-up, not to this round.

On a record under the convergence rules, a change may seal `remediation.max_rounds` rounds (`.ai/workflow.yml`) before a person decides; the tool refuses a further round and parks the change at `awaiting_human`. When the fix changes documentation alone, the person may reopen with `soft-foundry phase reopen remediate --docs-only`: verification, evaluation and attack keep their evidence, and the seal refuses any path outside documentation.

## Repairing a code-quality finding

A finding from the code-quality phase (`06a-code-quality/`) is usually a refactor: the behavior stays and the structure changes. Say which it is. A refactor preserves observable behavior; a fix changes a specified outcome on purpose. When a round does both, state the intended difference.

1. Define the observable contract at each affected entry point: return values, errors, persisted data, side effects and, where it matters, when they happen relative to a transaction. Find every caller, including background work and secondary workflows.
2. Write or extend a behavioral check before editing the implementation, in the repository's existing conventions and at a real entry point. For a pure refactor it passes against the original code. For a fix it fails against the original code for the intended reason. Resolve setup failures before reading anything into a result. Commit it before the code change, as `.ai/rules/testing.md` asks.
3. Make the smallest coherent edit across all affected callers. Reuse existing methods and conventions and leave unrelated code alone. Where more than one implementation is plausible, choose one and record the trade-off.
4. Rerun the same checks, then the affected suite and the checks the repository requires. Tell failures that were already there from ones the edit caused.
5. Report the exact commands run and their results before and after, what was skipped, and anything that blocked. Claim a passing suite only for what was run.

Verification and the code-quality phase then run again on the new commit.
