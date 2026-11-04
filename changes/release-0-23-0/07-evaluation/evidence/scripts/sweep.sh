#!/bin/bash
# Every CLI route against the 0.23.0 gem installed in a throwaway GEM_HOME, in a
# scratch repository with a throwaway HOME. Model-spending routes run --dry-run.
source /tmp/sf-eval-scripts/clean.sh
S=$1; G=$S/gemhome; A=$S/app; H=$S/shome; STUB=$S/stubbin; mkdir -p $A $H $STUB
export SF_HOME=$H
printf '#!/bin/sh\necho "stub claude: $*"\n' > $STUB/claude; chmod +x $STUB/claude
sf() { clean GEM_HOME=$G GEM_PATH=$G PATH="$STUB:/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin:/opt/homebrew/bin:/usr/bin:/bin" $G/bin/soft-foundry "$@"; }
pass=0; bad=0
# r <0|nz> <args...>: 0 = must exit 0; nz = a refusal, must exit non-zero
r() { exp=$1; shift; out=$(sf "$@" 2>&1 </dev/null); rc=$?
  if { [ $exp = 0 ] && [ $rc = 0 ]; } || { [ $exp = nz ] && [ $rc != 0 ]; }; then st=ok; pass=$((pass+1)); else st=UNEXPECTED; bad=$((bad+1)); fi
  if echo "$out" | grep -qE 'Traceback|NoMethodError|NameError|LoadError|cannot load such file|internal error|\.rb:[0-9]+:in'; then st="$st CRASH-TEXT"; bad=$((bad+1)); fi
  printf '%-14s rc=%s expect=%s | soft-foundry %s\n' "$st" $rc $exp "$*"
  echo "$out" | sed -E 's/#token=[A-Za-z0-9_-]+/#token=<redacted>/' | head -${LINES_SHOWN:-2} | cut -c1-150 | sed 's/^/      /'; }
cd $A; git init -q -b main . ; git config user.name Eval; git config user.email eval@example.invalid
mkdir -p lib; echo 'puts 1' > lib/app.rb; git add -A; git commit -qm init
echo "installed: $(sf version)"
echo "== top-level"; r 0 version; r 0 --version; r 0 -v; r 0 help; r nz not-a-command
echo "== bootstrap"; r 0 init --dry-run; r 0 init; git add -A; git commit -qm 'control plane'; r 0 onboard --maturity off; r 0 doctor; r 0 check; r 0 models; git add -A; git commit -qm onboard -q
echo "== hooks"; r 0 hooks install; r 0 hooks install --claude --local; r 0 hooks uninstall --claude --local; r 0 hooks install --sessions; r 0 hooks uninstall --sessions
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
echo "== guard"; for j in '{"tool_name":"Read","tool_input":{"file_path":"lib/app.rb"}}'; do out=$(echo "$j" | sf guard 2>&1); echo "rc=$? | soft-foundry guard (allowed read): [$(echo $out | cut -c1-120)]"; done
echo "== harness"; LINES_SHOWN=1 r 0 eval --json; out=$(sf eval 2>&1 | tail -1); echo "eval summary: $out"
out=$(sf ci 2>&1); rc=$?; echo "ci rc=$rc (demo records are unfinished on a change branch): $(echo "$out" | tail -1 | cut -c1-150)"
echo "== update (read-only, real GitHub)"; r 0 update
echo "== shell (claude stubbed; no session starts)"; r 0 shell claude --stub-arg; r nz shell not-a-shell
echo "== ui"; (sf ui --port 48791 > $S/ui.out 2>&1 & echo $! > $S/ui.pid); sleep 4; TOK=$(grep -oE 'token=[A-Za-z0-9_-]+' $S/ui.out | head -1 | cut -d= -f2)
echo "ui line: $(head -1 $S/ui.out | sed -E 's/#token=[A-Za-z0-9_-]+/#token=<redacted>/')"
echo "GET / no token: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:48791/)"
for route in /api/workflow /api/changes /api/processes /api/repositories; do
  echo "GET $route no token: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:48791$route) | with token: $(curl -s -o /dev/null -w '%{http_code}' -H "x-soft-foundry-token: $TOK" http://127.0.0.1:48791$route)"
done
pkill -f "soft-foundry ui --port 48791"; sleep 1; echo "ui stopped: $(pgrep -f 'soft-foundry ui --port 48791' | wc -l | tr -d ' ') left"
echo "SUMMARY pass=$pass unexpected=$bad"
