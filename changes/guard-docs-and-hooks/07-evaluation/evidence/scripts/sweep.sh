#!/bin/bash
# EVAL-007 (REQ-GDH-005; size full_route_sweep): every CLI route run from this
# checkout's library in a scratch repository with a throwaway HOME. Adapted
# from changes/release-0-23-0/07-evaluation/evidence/scripts/sweep.sh, which
# ran the installed gem; here `ruby -I<repo>/lib <repo>/exe/soft-foundry`
# runs the code on this branch. Model-spending routes run --dry-run; `shell`
# runs against a stub claude; `update` reaches real GitHub read-only through
# the session's proxy. Run as:
#   bash changes/guard-docs-and-hooks/07-evaluation/evidence/scripts/sweep.sh "$(mktemp -d)"
set -u
REPO=$(cd "$(dirname "$0")/../../../../.." && pwd)
S=$1; A=$S/app; H=$S/shome; STUB=$S/stubbin; mkdir -p "$A" "$H" "$STUB"
SF="ruby -I$REPO/lib $REPO/exe/soft-foundry"
printf '#!/bin/sh\necho "stub claude: $*"\n' > "$STUB/claude"; chmod +x "$STUB/claude"
clean() { env -i PATH="$STUB:/usr/local/bin:/usr/bin:/bin" HOME="$H" TMPDIR="$S" LANG=C.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
  HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${https_proxy:-}" SSL_CERT_FILE="${SSL_CERT_FILE:-}" NO_PROXY="${NO_PROXY:-}" "$@"; }
sf() { clean $SF "$@"; }
pass=0; bad=0
# r <0|nz> <args...>: 0 = must exit 0; nz = a refusal, must exit non-zero
r() { exp=$1; shift; out=$(sf "$@" 2>&1 </dev/null); rc=$?
  if { [ $exp = 0 ] && [ $rc = 0 ]; } || { [ $exp = nz ] && [ $rc != 0 ]; }; then st=ok; pass=$((pass+1)); else st=UNEXPECTED; bad=$((bad+1)); fi
  if echo "$out" | grep -qE 'Traceback|NoMethodError|NameError|LoadError|cannot load such file|internal error|\.rb:[0-9]+:in'; then st="$st CRASH-TEXT"; bad=$((bad+1)); fi
  if echo "$out" | grep -q $'\x1b'; then st="$st ANSI"; bad=$((bad+1)); fi
  printf '%-14s rc=%s expect=%s | soft-foundry %s\n' "$st" $rc $exp "$*"
  echo "$out" | sed -E 's/#token=[A-Za-z0-9_-]+/#token=<redacted>/' | head -${LINES_SHOWN:-2} | cut -c1-150 | sed 's/^/      /'; }
cd "$A" || exit 1; git init -q -b main . ; git config user.name Eval; git config user.email eval@example.invalid
mkdir -p lib; echo 'puts 1' > lib/app.rb; git add -A; git commit -qm init
echo "library: $(sf version) from $REPO"
echo "== top-level"; r 0 version; r 0 --version; r 0 -v; r nz help; r nz not-a-command
echo "== bootstrap"; r 0 init --dry-run; r 0 init; git add -A; git commit -qm 'control plane'; r 0 onboard --maturity off; r 0 doctor; r 0 check; r 0 models; git add -A; git commit -qm onboard -q
echo "== hooks"; r 0 hooks install; r 0 hooks install --claude --local; r 0 hooks uninstall --claude --local; r 0 hooks install --codex; r 0 hooks install --sessions; r 0 hooks uninstall --sessions; r 0 doctor
git checkout -q -b change/demo
echo "== change"; r 0 change new demo; r nz change new demo; r 0 change status; r 0 change status demo --json; r 0 change summary; r 0 change list; r 0 change list --json; r 0 change size --phase verify; r 0 change size --phase evaluate
r 0 change new demo2 --track iterative; r nz change new bad --track nonsense
r nz change vet demo; r nz change reopen demo --reason test; r nz change release demo --item A=b; r nz change discharge A --note x --change demo; r nz change close demo; r nz change request-discharge demo --pr 1
echo "== gate/phase"; LINES_SHOWN=3 r nz gate intake --change demo; r nz gate all --change demo; r nz phase seal intake --change demo; r nz phase reopen intake --reason test --change demo
r 0 phase run intake --change demo --dry-run; r 0 phase run evaluate attack --parallel --change demo --dry-run; r nz phase run not-a-phase --change demo --dry-run
echo "== content/learning"; r 0 scan; r 0 scan lib; r 0 learn list; r 0 learn promote --dry-run
echo "== budget"; r 0 budget status --change demo; r 0 budget record --phase intake --provider anthropic --model claude-opus-5-5 --tokens-in 1 --tokens-out 1 --usd 0.01 --change demo; r 0 budget threshold; r 0 budget threshold 5; r 0 budget threshold default
echo "== live state"; r 0 ps; r 0 ps --json; r 0 sessions; r 0 sessions --json; r nz resume demo
out=$(echo '{"session_id":"x","prompt":"hello","cwd":"'$A'"}' | sf session log --shell claude 2>&1); echo "ok-if-0 rc=$? | soft-foundry session log --shell claude: [$out]"; r 0 sessions hello; r 0 resume demo
echo "== guard (the hook itself, fed a payload on stdin; the record is at intake)"
for j in '{"tool_name":"Read","tool_input":{"file_path":"lib/app.rb"}}'; do out=$(echo "$j" | sf guard 2>&1); echo "rc=$? | soft-foundry guard (allowed read): [$(echo $out | cut -c1-120)]"; done
out=$(echo '{"tool_name":"Write","tool_input":{"file_path":"lib/app.rb","content":"x"}}' | sf guard 2>&1); echo "rc=$? (expect 2) | soft-foundry guard (intake writing lib): [$(echo $out | cut -c1-150)]"
out=$(echo '{"tool_name":"Bash","tool_input":{"command":"echo hi"}}' | sf guard 2>&1); echo "rc=$? (expect 0) | soft-foundry guard (pre-call): [$out]"
out=$(echo '{}' | sf guard --after 2>&1); echo "rc=$? (expect 0) | soft-foundry guard --after (nothing changed): [$out]"
echo "== harness"; LINES_SHOWN=1 r 0 eval --json; out=$(sf eval 2>&1 | tail -1); echo "eval summary: $out"
out=$(sf ci 2>&1); rc=$?; echo "ci rc=$rc (demo records are unfinished on a change branch): $(echo "$out" | tail -1 | cut -c1-150)"
echo "== update (read-only, real GitHub through the proxy)"; r 0 update
echo "== shell (claude stubbed; no session starts)"; r 0 shell claude --stub-arg; r nz shell not-a-shell
echo "== ui"; (sf ui --port 48791 > $S/ui.out 2>&1 & echo $! > $S/ui.pid); sleep 4; TOK=$(grep -oE 'token=[A-Za-z0-9_-]+' $S/ui.out | head -1 | cut -d= -f2)
echo "ui line: $(head -1 $S/ui.out | sed -E 's/#token=[A-Za-z0-9_-]+/#token=<redacted>/')"
echo "GET / no token: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:48791/)"
for route in /api/workflow /api/changes /api/processes /api/repositories; do
  echo "GET $route no token: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:48791$route) | with token: $(curl -s -o /dev/null -w '%{http_code}' -H "x-soft-foundry-token: $TOK" http://127.0.0.1:48791$route)"
done
kill "$(cat $S/ui.pid)" 2>/dev/null; pkill -f "soft-foundry ui --port 48791"; sleep 1; echo "ui stopped: $(pgrep -f 'soft-foundry ui --port 48791' | wc -l | tr -d ' ') left"
echo "SUMMARY pass=$pass unexpected=$bad"
