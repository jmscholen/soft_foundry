#!/bin/sh
# Evaluation evidence for purpose-and-scope, EVAL-007 (tool part).
# Runs the tool's entry commands in a clean clone of the commit, so the
# result does not depend on uncommitted files in the worktree.
#
# Usage: sh tool_smoke.sh <clean-clone-dir> <scratch-file>
set -u
cd "$1" || exit 1
SCRATCH="$2"
unset ANTHROPIC_API_KEY OPENAI_API_KEY XAI_API_KEY GEMINI_API_KEY OPENROUTER_API_KEY MAILTRAP_API_KEY PERSONAL_SENDGRID_API_KEY SOFT_FOUNDRY_PHASE

echo "EVAL-007 (tool part): the tool's entry commands in a clean clone of the commit"
echo "commit: $(git rev-parse HEAD)   branch: $(git branch --show-current)   uncommitted paths: $(git status --short | wc -l | tr -d ' ')"
echo "local main: $(git rev-parse main)   origin/HEAD ref removed (see 06-verification/results.md, Failures)"
echo "provider keys and SOFT_FOUNDRY_PHASE unset; ruby $(ruby -e 'print RUBY_VERSION')"
echo "Long output is cut to its first and last 8 lines; the exit status is always shown."

run() {
  echo
  echo "\$ soft-foundry $*"
  ruby -Ilib exe/soft-foundry "$@" > "$SCRATCH" 2>&1
  st=$?
  n=$(wc -l < "$SCRATCH" | tr -d ' ')
  if [ "$n" -gt 25 ]; then
    head -8 "$SCRATCH"
    echo "[... $((n - 16)) lines not shown ...]"
    tail -8 "$SCRATCH"
  else
    cat "$SCRATCH"
  fi
  echo "exit status: $st"
}

run version
run help
run check
run doctor
run scan
run change list
run change status purpose-and-scope
run change size --phase evaluate
run ci
