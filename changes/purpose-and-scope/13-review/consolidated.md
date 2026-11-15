# Consolidated Review

Commit reviewed: 58447638713364d48123cc4b810febff909b52a3. Outside `changes/` it is identical to the implementation commit d944d07. No blocking or major finding. Eight minor findings, REV-001 to REV-008.

## Functional
Conforms. AC-001, AC-002 and AC-003 (must) and AC-004, AC-005 and AC-006 (should) are met, each read against the text by this session. Minor: REV-002 (the sentence "Everything in between runs without them" in `README.md` overstates), REV-004 (the attack skill does not say whether the nine classes are the whole list), REV-005 (attack and review record a repository-write weakness in different places), REV-006 (two openings and a stale milestone section in `README.md`).

## Architecture
Conforms. The threat model is stated once and pointed to from the review skill. No contract file, template, workflow or policy changed, so no gate checks anything different. REV-005 is shared with the functional review.

## Security
Conforms. Nothing an outside party can reach changed. The narrowing of attack and review is a weakening of a required control, approved on the record under `human_decisions`. Minor: REV-001 (the review sentence also covers an alteration a reviewer actually sees in the record under review), REV-003 ("the runtime guard and the specification lock cover that" says more than is true), REV-007 (two guard configuration files in the worktree were modified at the start of this session and clean at its end, not caused by the change and not by this session), REV-008 (the approvals were typed in by the agent session, as their notes say).

## Accessibility
Conforms. Heading order, lists, plain wording and ASCII-only added text meet the document rules and WCAG 1.3.1, 1.4.1, 2.4.4 and 2.4.6. No advisory.

## Policy conformance
N/A. `surfaces.policy` is false; the patch was read in full and alters nothing the application collects, shares, retains, protects or promises. No policy text change is owed and no human decision is requested.

## Infrastructure
N/A. No infrastructure file is in the change's commits.

## Operations
Conforms. No runtime behavior changes. Rollback is a revert of d944d07. The branch merges after pull request 63.

## Blocking findings
None.

## Residual concerns
- **REV-001.** After this change a review grades any finding that needs repository write access as minor at most, and the sentence does not exempt an alteration the reviewer actually observes. The maintainer approved the narrowing; this is the risk that comes with it. A one-sentence addition in a later change would separate the two cases.
- **The accepted gap.** `rules` and `risk` in `metadata.yml` can still be edited by a party with write access (specification, "Security requirements"). REV-003 asks that the attack skill not describe this as covered.
- **For a person.** The guard, not this change (REV-007). The two guard configuration files that VER-001 and EVAL-F4 found modified were still modified when this session started and clean a few commands later, with no action by this session. Later the post-call hook reported a tamper after a command that wrote only review files, said it had removed the machine-local override, and wrote an untracked copy of the enforcement policy into `13-review/`, which this session removed so the seal would not commit it. Check that the local override is still where the maintainer expects, read the guard log, and fix the hook's use of the working directory in the guard follow-up.
- **Wording follow-ups for one later documentation change.** REV-002, REV-004, REV-005, REV-006.
- **Independence.** This review ran in a fresh session, on the same provider and model as the implementation (anthropic, claude-fable-5-2). The skill prefers a different provider; the gate will advise it.
- **Not rerun here.** `soft-foundry ci` and the full suite. Verification's runs are for the same tree outside `changes/`. This session reran `soft-foundry check` only.
