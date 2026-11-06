#!/bin/bash
# EVAL-004 follow-up (EVAL-F-002): during this evaluation the installed guard
# refused the session's own shell command `cd /tmp/sf-eval-sweep-*/app
# 2>/dev/null && ...` with "could not be decided (NoMethodError: undefined
# method `empty?' for nil)". Fail closed is what the header promises, but a
# NoMethodError is the guard's own parser failing, not a decision. This
# script feeds shell commands with globs to `soft-foundry guard` in the
# scratch repository guard-claims.sh built (argument 1: its app directory,
# on branch change/demo at the implement phase, policy block) to pin down
# which inputs trip it. Run as:
#   bash changes/guard-docs-and-hooks/07-evaluation/evidence/scripts/glob-outside.sh /tmp/<scratch>/app
set -u
REPO=$(cd "$(dirname "$0")/../../../../.." && pwd)
A=$1; H=$(dirname "$A")/home; mkdir -p "$H"
SF="ruby -I$REPO/lib $REPO/exe/soft-foundry"
clean() { env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$H" TMPDIR="$(dirname "$A")" LANG=C.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 "$@"; }
cd "$A" || exit 1
echo "scratch repository: $A, branch $(git branch --show-current), mode: $(clean $SF doctor 2>&1 | grep -o 'mode: [a-z]*')"
mkdir -p /tmp/sf-eval-globdir-one /tmp/sf-eval-globdir-two
t() { out=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | clean $SF guard 2>&1); rc=$?
  kind=decided; echo "$out" | grep -q "could not be decided" && kind=UNDECIDED
  printf '%-9s rc=%s | %s\n' "$kind" "$rc" "$1"; [ -n "$out" ] && printf '      %s\n' "$(printf '%s' "$out" | head -1 | cut -c1-200)"; }
echo "== globs inside the root"
t 'ls lib/*'
t 'ls lib/*.rb && cat lib/app.rb'
t 'ls no-such-dir/*'
echo "== globs outside the root, absolute"
t 'ls /tmp/sf-eval-globdir-*'
t 'cd /tmp/sf-eval-globdir-* && ls'
t 'cd /tmp/sf-eval-globdir-one && ls'
t 'cd /tmp/sf-eval-globdir-*/sub && ls'
t 'cd /tmp/no-such-prefix-*/app && ls'
t 'cd /tmp/no-such-prefix-*/app 2>/dev/null && ls'
t 'cat /etc/host*'
t 'ls /tmp/*'
t 'ls /nonexistent/*'
echo "== globs outside the root after a cd"
t 'cd /tmp && ls sf-eval-globdir-*'
t 'cd /tmp && cd sf-eval-globdir-* && ls'
t 'cd /tmp && cd no-such-prefix-* && ls'
echo "== a cd out of the root followed by more tokens in the same segment (shell_paths computes base once per segment, then reads cwd.empty? after cd set cwd to nil)"
t 'cd /tmp 2>/dev/null && ls'
t 'cd /tmp/sf-eval-globdir-one 2>/dev/null && ls'
t 'pushd /tmp >/dev/null && ls'
t 'cd /tmp && ls'
t 'cd /tmp; ls'
t 'cd lib 2>/dev/null && ls'
t 'cd .. 2>/dev/null && ls'
echo "== the session's own command, as refused in this repository"
t 'cd /tmp/sf-eval-sweep-*/app 2>/dev/null && echo x'
rmdir /tmp/sf-eval-globdir-one /tmp/sf-eval-globdir-two
