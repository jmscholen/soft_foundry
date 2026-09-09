#!/bin/bash
# EVAL-006: non-git directory refused; --allow-non-git installs; --force with --allow-non-git refused. Persona c.
source "$(dirname "$0")/lib.sh"
start_log EVAL-006-non-git.log "EVAL-006 non-git target refused unless --allow-non-git"
T=$SCRATCH/eval-006-plain; rm -rf "$T"; mkdir -p "$T"; cd "$T"
printf 'x\n' > file.txt
note "STEP 1: init in a plain directory (no .git anywhere above it)"
run env GIT_CEILING_DIRECTORIES=$SCRATCH $SF init --no-onboard; RC1=$?
runsh "ls -A"
note "STEP 2: init --allow-non-git"
run env GIT_CEILING_DIRECTORIES=$SCRATCH $SF init --allow-non-git --no-onboard; RC2=$?
runsh "ls -A; ls .ai | head -5; cat .gitignore"
note "STEP 3: init --allow-non-git --force"
run env GIT_CEILING_DIRECTORIES=$SCRATCH $SF init --allow-non-git --force --no-onboard; RC3=$?
note "ASSERTIONS"
assert "AC-002 refusal exit 1" "[ $RC1 -eq 1 ]"
assert "AC-002 message names the missing Git work tree and the flag" "sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -q 'is not inside a Git work tree; pass --allow-non-git to install anyway'"
assert "AC-002 nothing written on refusal" "sed -n '/STEP 1/,/STEP 2/p' '$LOG' | grep -qx 'file.txt'"
assert "--allow-non-git installs, exit 0" "[ $RC2 -eq 0 ] && [ -f $T/.ai/manifest.yml ] && [ -f $T/AGENTS.md ]"
assert "--allow-non-git with --force refused as unrecoverable, exit 1" "[ $RC3 -eq 1 ] && sed -n '/STEP 3/,\$p' '$LOG' | grep -q 'cannot be combined with --allow-non-git'"
finish EVAL-006
