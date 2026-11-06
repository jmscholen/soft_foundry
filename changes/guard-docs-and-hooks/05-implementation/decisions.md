# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Apply the hook install, the policy header, and the harness-eval note as one maintainer commit before the record existed | Apply them inside a phase | No skill's write set covers the guard's own configuration, protected policy, or harness material, and the guard refuses them to every skill; that is the boundary factory-readiness set | They are outside any phase's evidence by construction; verification, review, and judgment read them as REQ-GDH-001..003 |
| Describe the guard from `main`'s code (0.23.0), not from the factory-readiness drafts alone | Paste the drafts | gate-hardening and later changes landed after the drafts; the text must match what runs | The descriptions were checked against `lib/soft_foundry/guard.rb`, `hooks.rb`, and `cli.rb` on this branch |
| Leave `doctor`'s missing-PostToolUse report for a later change | Add it here | It is code, a proposal rather than a condition of approval, and the owner asked for the open conditions | Recorded as a non-goal in intake |
