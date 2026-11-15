# Evaluation Plan

Commit SHA: d272a5f538034b51e0e7264a4b2e81aadce1c87e (HEAD, `Record purpose-and-scope verify`). Outside `changes/` it is identical to the implementation commit d944d07.

## Intent being proven
A person or an agent who opens the documents this change edited learns what Soft Foundry is for, and a fresh attack or review session learns who the attacker is and what is out of scope, from the text alone. The change is text only (four Markdown files), so each journey is a read of a document as its reader meets it: from the top, in order, with nothing else loaded.

Size: `full_route_sweep` (`soft-foundry change size --phase evaluate`: no scope declared, so the whole repository is sized at the largest size). The repository has no web routes. The sweep is read here as every document the change edited (four, all covered by EVAL-001 to EVAL-006) plus every read-only entry command of the tool run once (EVAL-007). Commands that write or need a person's decision (`init`, `onboard`, `change new`, `change vet`, `change close`, `phase run`, `update`, `shell`, `ui`) were not run: the change touches no code, and running them would alter records this phase may not write.

## Personas
- **Adopter.** A person deciding whether to use Soft Foundry. Reads `README.md` from the top.
- **Agent starting a change.** Reads `.ai/README.md` from the top, as `AGENTS.md` step 1 tells it to.
- **Fresh attack session.** Has only `.ai/skills/adversarial-testing/SKILL.md`.
- **Fresh review session.** Has only `.ai/skills/review/SKILL.md`.
- **Reader without sight of layout.** Reads the added text as a screen reader or a plain-text terminal delivers it: headings in order, markup removed.
- **Maintainer.** Runs the tool after the edit and expects it to work as before.

## Journeys
Each journey is recorded in `journeys.yml` with its starting state, steps, assertions, evidence and result.

| Journey | Persona | Criteria | Requirements |
| --- | --- | --- | --- |
| EVAL-001 | Adopter | AC-001, AC-004 | REQ-001, REQ-004 |
| EVAL-002 | Agent starting a change | AC-001 | REQ-001 |
| EVAL-003 | Fresh attack session | AC-002 | REQ-002 |
| EVAL-004 | Fresh review session | AC-003 | REQ-003 |
| EVAL-005 | Adopter and agent, reading across the documents | AC-001, AC-002, AC-003 | REQ-001, REQ-002, REQ-003 |
| EVAL-006 | Reader without sight of layout | AC-005 | REQ-005 |
| EVAL-007 | Maintainer | AC-006 | REQ-006 |

Every must criterion (AC-001, AC-002, AC-003) has at least one journey. Every should criterion (AC-004, AC-005, AC-006) has one.

How the documents were read: every file was taken with `git show <commit>:<path>`, never from the working tree, because two control-plane files in the worktree differ from HEAD (06-verification finding VER-001). The tool commands of EVAL-007 ran in a clean clone of the commit.

## UI walkthrough evidence
There is no UI and no browser surface. The equivalent evidence is a transcript per journey under `evidence/`: the lines the reader meets, with line numbers, the heading outline as a renderer (pandoc) produces it, and the tool's output with exit statuses.

## Accessibility interaction
`surfaces.accessibility` is true: the result is Markdown a person reads.

- **Keyboard-only operation, focus order, visible focus, error identification.** Not applicable, and the reason is that the change adds no control: no link, form, button or command was added (`evidence/eval-006-accessibility.txt` shows no link, image or table in the added lines). The text is read in whatever viewer the reader already uses.
- **Screen-reader readable output.** Exercised in EVAL-006: the heading outline of each edited file as rendered (one level-1 heading, no level skipped), and the added sections converted to plain text with all markup removed, then read to see whether anything was lost.
- **Colour and symbols.** Exercised in EVAL-006: the added lines are searched for bytes outside printable ASCII and for colour words, and the plain-text render is read for any place where emphasis or a glyph carried the meaning.
