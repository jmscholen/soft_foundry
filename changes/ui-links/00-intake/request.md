# Change Intake

## User intent
"anytime there is a reference to something, make that a link to the reference... is this too much to ask?" Then: "or maybe have a hover popup that shows the reference and what it says", and: "make sure the hover show where the reference is located, as in file name".

## Desired outcome
- REQ-LINK-001: wherever the page names a change, a phase of a change, a phase of the lifecycle, or a repository, that name is a link to it: on the Repositories cards, the board (column headers and flags), a change (notes, advisories, check details, blocking items, the gate's skill, the timeline, the spend table), the Workflow (follows, then, can return to, ways back, tracks), and Running.
- REQ-LINK-002: hovering or focusing such a reference shows a popup with what it points at: a gate's state and failing checks; a phase's purpose, checks, and required files; a change's title, status, and phase; a repository's sessions and open and closed counts; a commit's identity and how to see it.
- REQ-LINK-003: every popup says where the reference lives, as a path: `changes/<slug>/metadata.yml`, `changes/<slug>/<phase>/handoff.yml`, `.ai/workflow.yml` and `.ai/skills/<skill>/`, the repository's own directory, or `.git` with the `git show` command; with the repository's directory in front when it is not the one on screen.
- REQ-LINK-004 (accessibility, WCAG 2.2 AA): the popup is a tooltip (`role="tooltip"`, `aria-describedby` on the reference while shown), opens on keyboard focus as well as hover, closes on Escape and on moving away, stays open while the pointer is over it (1.4.13); a non-link reference that has a popup is focusable; links are distinguishable (1.4.1).

## Constraints
- Page only. No new route or data: popups are built from what the page already holds (the change on screen, the list of repositories, the workflows fetched so far).
- Record text in popups is text, as everywhere on the page.

## Non-goals
- Linking to files themselves: the server serves no record file, so a path is shown, not opened.
- Linking a commit to a code host; the popup gives the `git show` command instead.
- Linking phase ids that appear as ordinary words in prose ("review", "verify"); only directory names (`13-review`) are recognised in free text, to avoid false links.

## Task classification
feature

## Initial risk
low. Page-only; the same text-only rendering; no server change.
