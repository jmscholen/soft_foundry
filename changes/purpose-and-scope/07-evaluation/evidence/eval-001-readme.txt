EVAL-001: a person adopting Soft Foundry opens README.md and reads from the top
commit: d272a5f538034b51e0e7264a4b2e81aadce1c87e

--- README.md, line 1 through the heading after Purpose ---
   1  # Soft Foundry
   2  
   3  Soft Foundry is a repository-native control plane for autonomous software engineering. The repository contains the engineering constitution; the CLI provides onboarding, runtime discovery, agent adapters, and eventually enforced lifecycle orchestration.
   4  
   5  ## Purpose
   6  
   7  Soft Foundry is an autonomous software factory. An agent builds a feature in an application by passing through gated phases, and each gate checks the work against what was asked for.
   8  
   9  - **The specification is locked.** What each gate checks is locked once a person approves it. The agent may not change the specification it is working to. The lock is lock and detect: the gate fails when a locked file changes. No phase searches for ways around the lock.
  10  - **The evidence phases look at the feature from the outside.** Verification and evaluation ask what a legitimate user expects of the feature. Attack asks what a bad actor would try through it, for example SQL injection through a new controller action. A party with write access to the repository editing a change record is outside that threat model.
  11  - **A person steps in at three points.** A person approves the specification before work starts, accepts or rejects the result at the end, and decides what happens when a change reaches the remediation cap. Everything in between runs without them.
  12  
  13  ## Agent: next implementation milestone

--- README.md heading outline (rendered) ---
h1: Soft Foundry
h2: Purpose
h2: Agent: next implementation milestone
h2: Install from this repository
h2: Onboard a repository
h2: Maturity assessment
h2: Change records and gates
h3: Seeing it in a browser
h3: Runtime enforcement: the guard hook
h3: Scanning the control plane as an attack surface
h3: Instincts: what a change learned
h3: RED and GREEN evidence
h3: Fresh-context phases: phase run
h3: Panels: independent drafts, an argument, one consensus
h3: Lifecycle tracks: gated or iterative
h3: Reopening a phase, parallel runs, and released changes
h4: Reopening a phase
h4: Running isolated phases in parallel
h4: Released changes
h3: Converging: what a change promises, and how many rounds it gets
h3: Closing a change record
h3: Go-live advisories and accessibility
h3: Privacy and security policy conformance
h3: Scoped verification: re-run only what a change can affect
h3: Everyday shortcuts: type and risk, blocked runs, summary, hidden characters
h4: Type and risk at creation
h4: A session that completes with blocking items
h4: Latest state of a change
h4: Quoting hidden characters in evidence
h4: Access-control parity
h3: Proving the gate: harness evals
h2: Updating
h2: Budget
h3: Subscription or API key
h3: Ledger and warnings
h2: Coding shells
h3: Finding and resuming sessions
h2: Adversarial testing and authorization
h2: Architecture
