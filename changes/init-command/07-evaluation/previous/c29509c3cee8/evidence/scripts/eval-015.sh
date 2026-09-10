#!/bin/bash
# EVAL-015: .ai is a symlink pointing outside the repository. Persona b (hostile or accidental layout).
source "$(dirname "$0")/lib.sh"
start_log EVAL-015-symlinked-ai.log "EVAL-015 .ai symlink to a directory outside the repository is refused, nothing written outside"
OUT=$SCRATCH/eval-015-outside; rm -rf "$OUT"; mkdir -p "$OUT"
T=$(new_repo eval-015); cd "$T"
printf 'x\n' > app.rb
ln -s "$OUT" .ai
run git add -A; run git commit -q -m "Project files with symlinked .ai"
runsh "ls -la .ai; ls -A $OUT | wc -l"
note "STEP 1: init"
run $SF init --no-onboard; RC1=$?
note "STEP 1 post-state"
runsh "ls -A $OUT | wc -l; ls -la .ai; git status --porcelain --untracked-files=all"
note "ASSERTIONS"
assert "AC-014 exit 1" "[ $RC1 -eq 1 ]"
assert "AC-014 message names the symlink" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '.ai is a symlink; init does not write through symlinks'"
assert "AC-014 nothing written outside the root" "[ \"$(ls -A $OUT | wc -l | tr -d ' ')\" = 0 ]"
assert "AC-014 nothing written inside the root" "[ -z \"$(git -C $T status --porcelain --untracked-files=all)\" ]"
finish EVAL-015
