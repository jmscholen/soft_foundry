# Change Intake

## User intent
Following an audit that found "merged PR, never closed the change record" recurring three separate times (soft_foundry's own `maturity-report` and `self-update`, and `my_ai`'s `bug-sweep-0910`), the user asked for a real enforcement mechanism rather than relying on memory:
- Problem A: closing a merged change is a deterministic fact and should be automated.
- Problem B: some acceptance criteria are only satisfiable by a real-world event (production observation, etc.); an agent shouldn't get to unilaterally declare those satisfied. The user proposed a PR-comment mechanism — the agent posts a request, a human replies with confirmation, and only then can the agent proceed — and asked to build it.

## Desired outcome
- `soft-foundry ci` fails when a change has reached judgment and that judged commit is already merged into the default branch, but the record isn't `closed` — reusing the existing pre-commit-hook enforcement point rather than new automation.
- `soft-foundry change close <slug>` performs the actual closure, refusing unless the change is merged (or `--force`), and refusing to discharge any `undischarged` acceptance criterion without either an explicit `--confirm ID` or a PR comment reading `CONFIRMED: <id>`.
- `soft-foundry change request-discharge <slug> --pr N` posts that request as a PR comment.

## Constraints
- Reuse the existing `ci`/pre-commit-hook enforcement point rather than inventing new bot infrastructure.
- The human-verification mechanism must be genuinely checkable by the tool (a PR comment it can read), not just an assertion in a commit message — that was the actual defect being fixed.
- Don't require `gh`/network access for the common case: an explicit `--confirm ID` must work standalone.

## Non-goals
- Not building an automatic bot that closes records unattended on every merge — the mechanical check is enforced at the next commit via `ci`, not via new CI/webhook infrastructure.
- Not validating the *content* of acceptance criteria or judgment reasoning — only whether the specific `undischarged` items a judgment already named have a matching confirmation.

## Task classification
Feature: new CLI subcommands (`change close`, `change request-discharge`) plus a new `ci` check, in soft_foundry's own codebase (real Ruby, with tests) — not a policy/documentation-only change like the two governance changes that preceded it this session.

## Initial risk
low — additive CLI commands and one new `ci` check; no change to existing gate/scoring semantics for any currently-passing change record (verified: `ci` still passes cleanly against this repository's own history after the change).
