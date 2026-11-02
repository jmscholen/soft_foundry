. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
hook() { printf '#!/bin/sh\nsleep %s\nexit 0\n' "$1" > .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit; }
state() { echo "--- state: $(git log --format='%h %s' -n 1) | staged: $(git diff --cached --name-only | tr '\n' ' ') | index.lock: $(test -e .git/index.lock && echo present || echo absent) | metadata current_phase: $(grep '^current_phase' changes/c1/metadata.yml) | branch_resolved: $(grep branch_resolved changes/c1/07-evaluation/handoff.yml)"; }
{
echo "== 7a redo: evaluate handoff complete on disk and NOT committed (as after a real session); SIGKILL the process group 1.5 s into a seal whose hook sleeps 4 s"
fresh a007r; $B/complete.rb $R evaluate HEAD; hook 4; git status --porcelain | grep -v soft-foundry/
perl -e 'setpgrp(0,0); exec @ARGV' -- $B/sf phase seal evaluate > $OUT/a007r-seal.txt 2>&1 & P=$!; sleep 1.5; kill -9 -- -$P; wait $P 2>/dev/null; echo "seal process exit $?"; cat $OUT/a007r-seal.txt; state
echo "-- gate attack in the half-state (attack complete on disk, uncommitted):"; $B/complete.rb $R attack HEAD >/dev/null; $B/sf gate attack | grep -E 'predecessor|FAIL|PASS'
echo "-- change status in the half-state:"; $B/sf change status 2>&1 | grep -E '07-|08-|phase:'
echo "-- rerun seal with the stale index.lock in place:"; run $B/sf phase seal evaluate | grep -v '^$'; state
echo "-- remove index.lock (as git's text says) and rerun:"; rm .git/index.lock; run $B/sf phase seal evaluate; state; echo "-- commit content:"; git show --stat --format='%s' HEAD | grep -E 'Record|changes/'
echo "== 7e: SIGKILL during the git add window instead (hook 0, kill at 0.35 s, 20 attempts; report any half-state seen)"
for i in 1 2 3 4 5 6 7 8 9 10; do fresh a007e >/dev/null; $B/complete.rb $R evaluate HEAD >/dev/null; hook 0; perl -e 'setpgrp(0,0); exec @ARGV' -- $B/sf phase seal evaluate > /dev/null 2>&1 & P=$!; sleep 0.3$i; kill -9 -- -$P 2>/dev/null; wait $P 2>/dev/null; echo "try $i (killed at 0.3${i}s): $(git log --format='%s' -n 1) | staged=[$(git diff --cached --name-only | tr '\n' ' ')] | index.lock=$(test -e .git/index.lock && echo present || echo absent) | $(grep '^current_phase' changes/c1/metadata.yml) | $(grep -c branch_resolved changes/c1/07-evaluation/handoff.yml) stamped"; done
} > $OUT/attack-007r.txt 2>&1
{
echo "== 8b redo: phase run evaluate (fake claude completes the handoff then sleeps 2 s) racing a manual phase seal fired at 1.0 s"
fresh a008r; hook 1; rm -f $OUT/fake-claude.log
PATH=/tmp/sf-attack2/fakebin2:$PATH $B/sf phase run evaluate --shell claude > $OUT/a008r-run.txt 2>&1 & P1=$!; sleep 1.0; $B/sf phase seal evaluate > $OUT/a008r-seal.txt 2>&1; echo "manual seal exit $?"; wait $P1; echo "phase run exit $?"
echo "-- phase run output:"; grep -v '^  [✓-] ' $OUT/a008r-run.txt; echo "-- manual seal output:"; cat $OUT/a008r-seal.txt; state; echo "-- Record commits: $(git log --format=%s | grep -c 'Record c1 evaluate')"; git log --format='%h %s' -n 4; $B/sf change status | grep -E '07-|08-'
echo "== 8c: the same race, manual seal at 2.5 s (after the session exits, while the runner is sealing)"
fresh a008c; hook 2; PATH=/tmp/sf-attack2/fakebin2:$PATH $B/sf phase run evaluate --shell claude > $OUT/a008c-run.txt 2>&1 & P1=$!; sleep 2.6; $B/sf phase seal evaluate > $OUT/a008c-seal.txt 2>&1; echo "manual seal exit $?"; wait $P1; echo "phase run exit $?"
echo "-- phase run output:"; grep -v '^  [✓-] ' $OUT/a008c-run.txt; echo "-- manual seal output:"; cat $OUT/a008c-seal.txt; state; echo "-- Record commits: $(git log --format=%s | grep -c 'Record c1 evaluate')"
} > $OUT/attack-008r.txt 2>&1
{
cd /tmp/sf-attack2/repos/a013
echo "== 13b redo: the fake shell is not executable (spawn fails): error path"; chmod -x /tmp/sf-attack2/fakebin/claude; PATH=/tmp/sf-attack2/fakebin:/usr/bin:/bin $B/sf phase run evaluate attack --parallel --env SECRET=hunter2 --shell claude > $OUT/a013b.txt 2>&1; echo "[exit $?] hunter2 occurrences: $(grep -c hunter2 $OUT/a013b.txt)"; grep -v '^  [✓-] ' $OUT/a013b.txt | grep -v '^billing\|^ *set SOFT' | head -8; chmod +x /tmp/sf-attack2/fakebin/claude
echo "== 13e redo: value 'phase' (a substring of normal output)"; PATH=/tmp/sf-attack2/fakebin:/usr/bin:/bin $B/sf phase run evaluate attack --parallel --env SECRET=phase --shell claude > $OUT/a013e.txt 2>&1; echo "[exit $?]"; grep -v '^  [✓-] ' $OUT/a013e.txt | grep -v '^billing\|^ *set SOFT' | grep -i 'hidden\|phase' | head -6
echo "== 13f: a value that equals the slug 'c1'"; PATH=/tmp/sf-attack2/fakebin:/usr/bin:/bin $B/sf phase run evaluate attack --parallel --env SECRET=c1 --shell claude 2>&1 | grep -i 'hidden' | head -3
} > $OUT/attack-013r.txt 2>&1
{
echo "== X2: a session for change c1 (SOFT_FOUNDRY_PHASE=intake) seals record c2's intake; c2's branch does not exist, so the branch check cannot refuse"
fresh ax2; $B/sf change new c2 --branch change/c2 >/dev/null 2>&1; echo "c2 branch: $(grep -A2 '^git:' changes/c2/metadata.yml | grep branch)"; git add -A; git commit -qm "record c2"; $RB -I/Users/jscholen-iou/dev/soft_foundry/lib -rsoft_foundry -rsoft_foundry/harness_eval -e 'r=SoftFoundry::ChangeRecord.new(ARGV[0],"c2",control_plane: SoftFoundry::ControlPlane.new(ARGV[0])); SoftFoundry::HarnessEval.complete_phase!(r,"intake",`git -C #{ARGV[0]} rev-parse HEAD`.strip)' $R; run env SOFT_FOUNDRY_PHASE=intake $B/sf-env phase seal intake --change c2; git log --format='%h %s %D' -n 2
echo "== X3: what the gate's JSON looks like and where the session id is shown"; cd /Users/jscholen-iou/dev/soft_foundry; grep -n '"--json"\|json' lib/soft_foundry/cli.rb | grep -i 'gate\|status\|json' | head -8; echo "-- change_summary.rb mentions of session/executed:"; grep -n -i 'session\|executed' lib/soft_foundry/change_summary.rb | head; echo "-- advisory.rb mentions of session id:"; grep -n -i 'session_id\|ledger' lib/soft_foundry/advisory.rb | head -5
} > $OUT/extras-cross-record-json.txt 2>&1
echo batch3b done
