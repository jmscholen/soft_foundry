#!/bin/sh
# Evaluation evidence for purpose-and-scope. Reads every document with
# `git show <commit>:<path>`, never from the working tree, so the output
# describes the commit and not uncommitted files.
#
# Usage: sh reader_journeys.sh <commit> <intake-commit> <output-dir>
set -u
COMMIT="$1"
INTAKE="$2"
OUT="$3"

show() { git show "$COMMIT:$1"; }

# Heading outline as a renderer sees it (pandoc HTML), so a "#" inside a
# code block is not counted as a heading.
outline() {
  show "$1" | pandoc -f gfm -t html --wrap=none | grep -o -E '<h[1-6][^>]*>.*</h[1-6]>' |
    sed -E 's/<h([1-6])[^>]*>/h\1: /; s/<\/h[1-6]>//; s/<[^>]+>//g'
}

# The file from line 1 through the heading that follows "## Purpose".
top_through_next_heading() {
  show "$1" | awk '
    { printf "%4d  %s\n", NR, $0 }
    seen && /^## / { exit }
    /^## Purpose$/ { seen = 1 }'
}

# One section, heading line through the line before the next "## " heading.
section() {
  show "$1" | awk -v h="$2" '
    $0 == h { on = 1; printf "%4d  %s\n", NR, $0; next }
    on && /^## / { exit }
    on { printf "%4d  %s\n", NR, $0 }'
}

{
  echo "EVAL-001: a person adopting Soft Foundry opens README.md and reads from the top"
  echo "commit: $COMMIT"
  echo
  echo "--- README.md, line 1 through the heading after Purpose ---"
  top_through_next_heading README.md
  echo
  echo "--- README.md heading outline (rendered) ---"
  outline README.md
} > "$OUT/eval-001-readme.txt"

{
  echo "EVAL-002: an agent starting a change opens .ai/README.md and reads from the top"
  echo "commit: $COMMIT"
  echo
  echo "--- .ai/README.md, line 1 through the heading after Purpose ---"
  top_through_next_heading .ai/README.md
  echo
  echo "--- .ai/README.md heading outline (rendered) ---"
  outline .ai/README.md
} > "$OUT/eval-002-ai-readme.txt"

{
  echo "EVAL-003: a fresh attack session reads only .ai/skills/adversarial-testing/SKILL.md"
  echo "commit: $COMMIT"
  echo
  echo "--- section 'The attacker' ---"
  section .ai/skills/adversarial-testing/SKILL.md "## The attacker"
  echo
  echo "--- heading outline (rendered) ---"
  outline .ai/skills/adversarial-testing/SKILL.md
  echo
  echo "--- other lines in the file that say what to attack (for agreement with the section) ---"
  show .ai/skills/adversarial-testing/SKILL.md | grep -n -E '^Try to make|^ATTACK is broader|^On a record under'
} > "$OUT/eval-003-attack-skill.txt"

{
  echo "EVAL-004: a fresh review session reads only .ai/skills/review/SKILL.md"
  echo "commit: $COMMIT"
  echo
  echo "--- the grading paragraph and its neighbours ---"
  show .ai/skills/review/SKILL.md | grep -n -E '^On a record under the convergence|^Grade findings|^Every finding states'
  echo
  echo "--- the file the paragraph points to exists at the commit ---"
  for p in .ai/skills/adversarial-testing/SKILL.md; do
    if git cat-file -e "$COMMIT:$p" 2>/dev/null; then echo "pass: $p exists"; else echo "fail: $p missing"; fi
  done
} > "$OUT/eval-004-review-skill.txt"

{
  echo "EVAL-005: the four documents agree with each other"
  echo "commit: $COMMIT"
  echo
  echo "--- Purpose section: README.md (<) against .ai/README.md (>) ---"
  show README.md | awk '/^## Purpose$/{on=1;next} on&&/^## /{exit} on' > "$OUT/.purpose-a"
  show .ai/README.md | awk '/^## Purpose$/{on=1;next} on&&/^## /{exit} on' > "$OUT/.purpose-b"
  diff "$OUT/.purpose-a" "$OUT/.purpose-b" > "$OUT/.purpose-diff"
  st=$?
  fold -s -w 160 "$OUT/.purpose-diff"
  echo "(diff exit status: $st; 1 means the wording differs, lines above)"
  rm -f "$OUT/.purpose-diff"
  rm -f "$OUT/.purpose-a" "$OUT/.purpose-b"
  echo
  echo "--- paths named in the added text resolve at the commit ---"
  # .ai/README.md names paths relative to .ai/
  for p in .ai/skills/adversarial-testing/SKILL.md .ai/skills/review/SKILL.md; do
    if git cat-file -e "$COMMIT:$p" 2>/dev/null; then echo "pass: $p exists"; else echo "fail: $p missing"; fi
  done
  echo
  echo "--- the claims the Purpose text makes about the workflow, against .ai/workflow.yml at the commit ---"
  git show "$COMMIT:.ai/workflow.yml" | grep -n -E '^remediation:|^  max_rounds:|remediation cap'
} > "$OUT/eval-005-consistency.txt"

{
  echo "EVAL-006: the added text read without sight of layout, colour or glyphs"
  echo "commit: $COMMIT    intake commit: $INTAKE"
  for f in README.md .ai/README.md .ai/skills/adversarial-testing/SKILL.md .ai/skills/review/SKILL.md; do
    echo
    echo "=== $f ==="
    echo "--- heading levels in order (rendered); a jump of more than one level down is reported ---"
    outline "$f" | awk -F: '
      { lvl = substr($1, 2) + 0
        if (NR == 1 && lvl != 1) { print "fail: first heading is not level 1"; bad = 1 }
        if (NR > 1 && lvl > prev + 1) { print "fail: level skipped before: " $0; bad = 1 }
        if (lvl == 1) h1++
        prev = lvl }
      END { printf "%s: %d headings, %d at level 1, no level skipped = %s\n", (bad || h1 != 1) ? "fail" : "pass", NR, h1, bad ? "no" : "yes" }'
    echo "--- lines the change added: count, and any byte outside printable ASCII ---"
    git diff "$INTAKE" "$COMMIT" -- "$f" | grep -E '^\+[^+]' | sed 's/^+//' > "$OUT/.added"
    wc -l < "$OUT/.added" | awk '{ print "added non-blank lines: " $1 }'
    if LC_ALL=C grep -n '[^ -~]' "$OUT/.added"; then echo "fail: non-ASCII or control byte above"; else echo "pass: every added byte is printable ASCII"; fi
    echo "--- added lines: links, images, tables, colour words ---"
    if grep -n -E '\]\(|<a |!\[|^\|' "$OUT/.added"; then echo "note: link, image or table above"; else echo "pass: no link, image or table added"; fi
    if grep -n -i -E '\b(red|green|yellow|amber|blue|orange|colou?r(ed)?)\b' "$OUT/.added"; then echo "note: colour word above"; else echo "pass: no colour word added"; fi
    rm -f "$OUT/.added"
  done
  echo
  echo "=== the added sections as plain text (pandoc -t plain): what is left when all markup is removed ==="
  echo "--- README.md, Purpose ---"
  show README.md | awk '/^## Purpose$/{on=1} on&&/^## /&&!/Purpose/{exit} on' | pandoc -f gfm -t plain --wrap=none
  echo "--- .ai/README.md, Purpose ---"
  show .ai/README.md | awk '/^## Purpose$/{on=1} on&&/^## /&&!/Purpose/{exit} on' | pandoc -f gfm -t plain --wrap=none
  echo "--- adversarial-testing SKILL.md, The attacker ---"
  show .ai/skills/adversarial-testing/SKILL.md | awk '/^## The attacker$/{on=1} on&&/^## /&&!/The attacker/{exit} on' | pandoc -f gfm -t plain --wrap=none
  echo "--- review SKILL.md, grading paragraph ---"
  show .ai/skills/review/SKILL.md | grep -E '^Grade findings' | pandoc -f gfm -t plain --wrap=none
} > "$OUT/eval-006-accessibility.txt"

{
  echo "EVAL-007 (diff part): paths that differ between the intake commit and the commit"
  echo "commit: $COMMIT    intake commit: $INTAKE"
  echo
  echo "--- outside changes/ ---"
  git diff --name-status "$INTAKE" "$COMMIT" -- . ':!changes'
  echo
  echo "--- under lib/, exe/ or test/ ---"
  n=$(git diff --name-only "$INTAKE" "$COMMIT" -- lib exe test | wc -l | tr -d ' ')
  git diff --name-only "$INTAKE" "$COMMIT" -- lib exe test
  if [ "$n" = "0" ]; then echo "pass: 0 paths under lib/, exe/ or test/"; else echo "fail: $n paths under lib/, exe/ or test/"; fi
  echo
  echo "--- all paths that differ: count ---"
  git diff --name-only "$INTAKE" "$COMMIT" | wc -l | awk '{ print $1 " paths" }'
} > "$OUT/eval-007-diff.txt"

echo "wrote evidence to $OUT"
