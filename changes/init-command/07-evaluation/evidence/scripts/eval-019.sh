#!/bin/bash
# EVAL-019: pointer-file block detection (AGENTS.md/CLAUDE.md) still works for byte-identical
# files reproduced by a fresh `git clone`, not just the original working tree. Legitimate-use
# companion to the agent_files.rb block-detection normalization (ATTACK-012 false-conflict family).
source "$(dirname "$0")/lib.sh"
start_log EVAL-019-fresh-clone-block-detection.log "EVAL-019 pointer-file block is recognized (skipped) after a fresh git clone"
T=$(new_repo eval-019); cd "$T"
printf 'puts 1\n' > app.rb
run git add -A; run git commit -q -m "Project files"
note "STEP 1: install, then commit the generated AGENTS.md/CLAUDE.md"
run $SF init --no-onboard; RC1=$?
run shasum -a 256 AGENTS.md CLAUDE.md
run git add -A; run git commit -q -m "Adopt Soft Foundry"
CLONE=$SCRATCH/eval-019-clone
rm -rf "$CLONE"
note "STEP 2: fresh git clone of the committed repository (byte-identical working tree)"
run git clone -q "$T" "$CLONE"
cd "$CLONE"
run git config user.email maintainer@example.invalid
run git config user.name Maintainer
run git config commit.gpgsign false
run shasum -a 256 AGENTS.md CLAUDE.md
runsh "cmp $T/AGENTS.md $CLONE/AGENTS.md && cmp $T/CLAUDE.md $CLONE/CLAUDE.md && echo 'clone is byte-identical to origin'"
IDENTICAL=$?
note "STEP 3: init again inside the fresh clone"
run $SF init --no-onboard; RC2=$?
run git status --porcelain
note "ASSERTIONS"
assert "setup: first install exit 0" "[ $RC1 -eq 0 ]"
assert "clone reproduced AGENTS.md and CLAUDE.md byte-identical to the original" "[ $IDENTICAL -eq 0 ]"
assert "AC-003/AC-004/AC-005 init in the fresh clone exits 0" "[ $RC2 -eq 0 ]"
assert "AGENTS.md recognized as block present (skipped), not a false conflict" "sed -n '/STEP 3/,\$p' '$LOG' | grep -q '^skipped   AGENTS.md  (block present)'"
assert "CLAUDE.md recognized as block present (skipped), not a false conflict" "sed -n '/STEP 3/,\$p' '$LOG' | grep -q '^skipped   CLAUDE.md  (block present)'"
assert "no conflict/updated status anywhere in the fresh-clone run" "! sed -n '/STEP 3/,\$p' '$LOG' | grep -Eq '^(conflict|updated) '"
assert "git status clean after init in the fresh clone (fully idempotent)" "[ -z \"\$(git -C $CLONE status --porcelain)\" ]"
finish EVAL-019
