# Shared helpers for evaluation journeys. Sourced by each journey script.
set -u
REPO=/Users/jscholen-iou/dev/soft_foundry
RUBY=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
SF="$RUBY -I$REPO/lib $REPO/exe/soft-foundry"
SCRATCH=/private/tmp/claude-501/-Users-jscholen-iou-dev-soft-foundry/87281b62-7130-41d8-9d9a-ab1e96399132/scratchpad/eval4
EVID=$REPO/changes/init-command/07-evaluation/evidence
LOG=""

start_log() {
  LOG="$EVID/$1"
  : > "$LOG"
  echo "### journey: $2" >> "$LOG"
  echo "### ruby: $RUBY ($($RUBY -v))" >> "$LOG"
  echo "### soft-foundry source: $REPO (HEAD $(git -C "$REPO" rev-parse HEAD))" >> "$LOG"
  echo "### captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"
}

note() { printf '\n### %s\n' "$*" >> "$LOG"; }

# run <cmd...>: logs command, combined stdout+stderr, and exit code; returns the exit code.
run() {
  printf '\n$ %s\n' "$*" >> "$LOG"
  "$@" >> "$LOG" 2>&1
  local rc=$?
  echo "exit=$rc" >> "$LOG"
  return $rc
}

# runsh <string>: same, but through a shell (for pipes and redirections).
runsh() {
  printf '\n$ %s\n' "$1" >> "$LOG"
  bash -c "$1" >> "$LOG" 2>&1
  local rc=$?
  echo "exit=$rc" >> "$LOG"
  return $rc
}

# assert <description> <shell condition>
PASSES=0; FAILS=0
assert() {
  if bash -c "$2" >/dev/null 2>&1; then
    echo "ASSERT PASS: $1" >> "$LOG"; PASSES=$((PASSES+1))
  else
    echo "ASSERT FAIL: $1   [condition: $2]" >> "$LOG"; FAILS=$((FAILS+1))
  fi
}

finish() {
  printf '\n### assertions: %d passed, %d failed\n' "$PASSES" "$FAILS" >> "$LOG"
  echo "$1: $PASSES passed, $FAILS failed -> $LOG"
}

new_repo() {
  local dir="$SCRATCH/$1"
  rm -rf "$dir"; mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email maintainer@example.invalid
  git -C "$dir" config user.name Maintainer
  git -C "$dir" config commit.gpgsign false
  echo "$dir"
}
