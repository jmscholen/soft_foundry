EVAL-002: an agent starting a change opens .ai/README.md and reads from the top
commit: d272a5f538034b51e0e7264a4b2e81aadce1c87e

--- .ai/README.md, line 1 through the heading after Purpose ---
   1  # `.ai/` Control Plane
   2  
   3  `.ai/` defines HOW engineering work is performed. It contains lifecycle orchestration, skill contracts, policies, model profiles, maturity policy, repository capability assessment, runtime configuration, and deterministic checks. It should not become a duplicate home for product/domain documentation; canonical human/agent product documentation belongs under `docs/`.
   4  
   5  ## Purpose
   6  
   7  Soft Foundry is an autonomous software factory. An agent builds a feature in an application by passing through gated phases, and each gate checks the work against what was asked for.
   8  
   9  - **The specification is locked.** What each gate checks is locked once a person approves it. The agent may not change the specification it is working to. The lock is lock and detect: the gate fails when a locked file changes. No phase searches for ways around the lock.
  10  - **The evidence phases look at the feature from the outside.** Verification and evaluation ask what a legitimate user expects of the feature. Attack asks what a bad actor would try through it. A party with write access to the repository editing a change record is outside that threat model (`skills/adversarial-testing/SKILL.md`, `skills/review/SKILL.md`).
  11  - **A person steps in at three points.** A person approves the specification before work starts, accepts or rejects the result at the end, and decides what happens when a change reaches the remediation cap.
  12  
  13  ## Skills and modes

--- .ai/README.md heading outline (rendered) ---
h1: .ai/ Control Plane
h2: Purpose
h2: Skills and modes
h2: Layout
h2: Phase lifecycle controls
h2: Repository maturity and gap analysis
