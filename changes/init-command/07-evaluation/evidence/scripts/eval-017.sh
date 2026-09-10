#!/bin/bash
# EVAL-017: a normal git-ignored build artifact outside .ai/ (tmp/cache) does not interfere
# with init: not swept into any conflict/dirty logic, stays ignored, install proceeds normally.
# Legitimate-use companion to the V3 remediation (ignored paths now count as dirty for .ai/ files).
source "$(dirname "$0")/lib.sh"
start_log EVAL-017-gitignored-build-artifact.log "EVAL-017 non-.ai/ git-ignored build artifact is inert to init"
T=$(new_repo eval-017); cd "$T"
printf 'node_modules/\ntmp/\n' > .gitignore
mkdir -p tmp
printf 'binary-ish build cache, not source\n' > tmp/cache
printf 'puts 1\n' > app.rb
run git add -A; run git commit -q -m "Project files with a gitignored tmp/cache build artifact"
run git check-ignore -v tmp/cache
note "STEP 1: first install with the ignored artifact present"
run $SF init --no-onboard; RC1=$?
note "STEP 1 post-state"
run git status --porcelain --untracked-files=all --ignored=matching
runsh "test -f tmp/cache && echo 'tmp/cache still present'"
runsh "cat tmp/cache"
note "STEP 2: commit the install, then edit an owned .ai/ file uncommitted to prove the artifact isn't conflated with real dirty .ai/ paths"
run git add -A; run git commit -q -m "Adopt Soft Foundry"
runsh "printf '\nuncommitted local note\n' >> .ai/rules/general.md"
note "STEP 2 second run: only the actually-edited .ai file conflicts; the artifact is untouched and irrelevant"
run $SF init --no-onboard; RC2=$?
run git status --porcelain --untracked-files=all --ignored=matching
runsh "git checkout -- .ai/rules/general.md; echo reverted"
note "ASSERTIONS"
assert "setup: first install exit 0" "[ $RC1 -eq 0 ]"
assert "install succeeded (check: ok) with the ignored artifact present" "sed -n '/STEP 1: first install/,/STEP 1 post/p' '$LOG' | grep -q '^check: ok'"
assert "tmp/cache untouched (content unchanged)" "[ \"\$(cat $T/tmp/cache)\" = 'binary-ish build cache, not source' ]"
assert "tmp/cache stays ignored, never appears as a managed action" "! sed -n '/STEP 1: first install/,/STEP 1 post/p' '$LOG' | grep -q 'tmp/cache'"
assert "git status after install shows tmp/cache only as ignored (!!), not untracked or conflicting" "sed -n '/STEP 1 post-state/,/STEP 2/p' '$LOG' | grep -q '^!! tmp/'"
assert "AC-006 second run: only the actually-edited .ai file is a conflict, exit 3" "[ $RC2 -eq 3 ] && sed -n '/STEP 2 second run/,\$p' '$LOG' | grep -q '^conflict  .ai/rules/general.md  (uncommitted modifications)'"
assert "the ignored build artifact never appears in the conflicts: line" "! sed -n '/STEP 2 second run/,\$p' '$LOG' | grep '^conflicts: ' | grep -q 'tmp/'"
finish EVAL-017
