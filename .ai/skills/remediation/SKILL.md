# Remediation
Repair findings from verification, evaluation, attack, or review without altering their evidence or expected outcomes. Record root cause and remediation. After any implementation change, downstream validation evidence becomes stale and applicable stages must rerun.

Fix what blocks: unmet must criteria, and blocking and major findings that name a failure. Carry minor findings forward in the summary instead of rewriting text that then needs checking again; every rewritten sentence is a new claim. Fix the smallest thing that resolves the finding: narrow or remove a claim rather than add a qualified one. A finding marked `outside_change` belongs to its follow-up, not to this round.

On a record under the convergence rules, a change may seal `remediation.max_rounds` rounds (`.ai/workflow.yml`) before a person decides; the tool refuses a further round and parks the change at `awaiting_human`. When the fix changes documentation alone, the person may reopen with `soft-foundry phase reopen remediate --docs-only`: verification, evaluation and attack keep their evidence, and the seal refuses any path outside documentation.
