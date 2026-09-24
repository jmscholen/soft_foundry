# Learning
Extract reusable engineering lessons after judgment. Propose new rules, deterministic checks, or harness-level evals from escaped defects, review catches, repeated failures, and successful patterns. Proposed workflow changes are not silently self-applied.

Write each lesson worth keeping as an instinct in `instincts.yml`: a trigger an agent will recognise, one imperative action, a confidence from 0 to 1 that says how sure this record makes you, and the finding or phase in this record that is the evidence. Do not promote them yourself: `soft-foundry learn promote`, run through a later change's record, copies instincts at or above the policy threshold into `.ai/rules/learned.md`, which implementation and exploration load with the baseline rules.
