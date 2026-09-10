#!/bin/bash
# EVAL-002: upgrade a repository that already has AGENTS.md and CLAUDE.md with its own content. Persona b.
source "$(dirname "$0")/lib.sh"
start_log EVAL-002-pointer-files-preserved.log "EVAL-002 existing AGENTS.md and CLAUDE.md preserved, block appended once"
T=$(new_repo eval-002); cd "$T"
printf '# Acme Service\n\nRun `make test` before every commit.\nNever touch `db/legacy/`.\n' > AGENTS.md
printf '# Notes for Claude\n\nPrefer small diffs.' > CLAUDE.md   # deliberately no trailing newline
printf 'print(1)\n' > main.py
run git add -A; run git commit -q -m "Project files"
run shasum -a 256 AGENTS.md CLAUDE.md
cp AGENTS.md "$SCRATCH/eval-002-AGENTS.orig"; cp CLAUDE.md "$SCRATCH/eval-002-CLAUDE.orig"
note "STEP 1: first run"
run $SF init --no-onboard; RC1=$?
note "STEP 1 post-state"
run cat AGENTS.md
run cat CLAUDE.md
runsh "head -c $(wc -c < $SCRATCH/eval-002-AGENTS.orig) AGENTS.md | cmp - $SCRATCH/eval-002-AGENTS.orig && echo 'AGENTS.md original prefix verbatim'"
A_PREFIX=$?
runsh "head -c $(wc -c < $SCRATCH/eval-002-CLAUDE.orig) CLAUDE.md | cmp - $SCRATCH/eval-002-CLAUDE.orig && echo 'CLAUDE.md original prefix verbatim'"
C_PREFIX=$?
runsh "grep -c 'soft-foundry:begin' AGENTS.md; grep -c 'soft-foundry:begin' CLAUDE.md"
run git diff --stat
run git add -A; run git commit -q -m "Adopt Soft Foundry"
note "STEP 2: second run"
run $SF init --no-onboard; RC2=$?
runsh "grep -c 'soft-foundry:begin' AGENTS.md; grep -c 'soft-foundry:begin' CLAUDE.md"
run git status --porcelain
note "ASSERTIONS"
assert "AC-004 first run exit 0" "[ $RC1 -eq 0 ]"
assert "AC-004 AGENTS.md original text preserved verbatim as prefix" "[ $A_PREFIX -eq 0 ]"
assert "AC-004 AGENTS.md reported updated (block appended)" "sed -n '/STEP 1: first run/,/exit=/p' '$LOG' | grep -q '^updated   AGENTS.md  (block appended)'"
assert "AC-004 AGENTS.md has exactly one begin marker" "[ \"$(grep -c 'soft-foundry:begin' $T/AGENTS.md)\" = 1 ]"
assert "AC-005 CLAUDE.md original content preserved verbatim as prefix" "[ $C_PREFIX -eq 0 ]"
assert "AC-005 CLAUDE.md reported updated (block appended)" "sed -n '/STEP 1: first run/,/exit=/p' '$LOG' | grep -q '^updated   CLAUDE.md  (block appended)'"
assert "AC-005 CLAUDE.md has exactly one begin marker" "[ \"$(grep -c 'soft-foundry:begin' $T/CLAUDE.md)\" = 1 ]"
assert "AC-004/AC-005 second run exit 0" "[ $RC2 -eq 0 ]"
assert "AC-004 second run reports AGENTS.md skipped" "sed -n '/STEP 2: second run/,/exit=/p' '$LOG' | grep -q '^skipped   AGENTS.md'"
assert "AC-005 second run reports CLAUDE.md skipped" "sed -n '/STEP 2: second run/,/exit=/p' '$LOG' | grep -q '^skipped   CLAUDE.md'"
assert "AC-004/AC-005 second run appends nothing (git clean)" "[ -z \"$(git -C $T status --porcelain)\" ]"
finish EVAL-002
