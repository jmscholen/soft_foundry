. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
hook() { printf '#!/bin/sh\nsleep %s\nexit 0\n' "$1" > .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit; }
state() { echo "--- state: $(git log --format='%h %s' -n 1) | staged: $(git diff --cached --name-only | tr '\n' ' ') | index.lock: $(test -e .git/index.lock && echo present || echo absent) | metadata current_phase: $(grep '^current_phase' changes/c1/metadata.yml) | branch_resolved: $(grep branch_resolved changes/c1/07-evaluation/handoff.yml)"; }
# ---------- ATTACK-007: kill phase seal between the metadata write and the commit
{
echo "== 7a: SIGKILL the whole process group (ruby + git + hook) 1.5 s into a seal whose pre-commit hook sleeps 4 s"
fresh a007; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"; hook 4
perl -e 'setpgrp(0,0); exec @ARGV' -- $B/sf phase seal evaluate > $OUT/a007-seal.txt 2>&1 & P=$!; sleep 1.5; kill -9 -- -$P; wait $P; echo "seal process exit $?"; cat $OUT/a007-seal.txt; state
echo "-- gate attack in the half-state (attack complete on disk):"; $B/complete.rb $R attack HEAD >/dev/null; $B/sf gate attack | grep -E 'predecessor|FAIL|PASS'; git checkout -q -- changes/c1/08-attack
echo "-- rerun phase seal evaluate (hook still sleeps 4 s):"; run $B/sf phase seal evaluate; state; git status --porcelain | grep -v soft-foundry/
echo "== 7b: SIGKILL only the ruby parent while git runs the hook (git finishes on its own)"
fresh a007b; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"; hook 4
$B/sf phase seal evaluate > $OUT/a007b-seal.txt 2>&1 & P=$!; sleep 1.5; pkill -9 -f "soft-foundry phase seal evaluate" ; wait $P; echo "seal process exit $?"; cat $OUT/a007b-seal.txt; sleep 4; state
echo "-- rerun:"; run $B/sf phase seal evaluate; state
echo "== 7c: hook refuses the commit (exit 1): what the seal leaves and says"
fresh a007c; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"; printf '#!/bin/sh\necho "hook: refusing"; exit 1\n' > .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit
run $B/sf phase seal evaluate; state; echo "-- fix the hook and rerun:"; hook 0; run $B/sf phase seal evaluate; state
echo "== 7d: a stale .git/index.lock left by a killed git"; fresh a007d; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"; touch .git/index.lock; run $B/sf phase seal evaluate; state; rm .git/index.lock; run $B/sf phase seal evaluate | tail -1
} > $OUT/attack-007.txt 2>&1
# ---------- ATTACK-008: two seals of one phase at once
{
fresh a008; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"; hook 2
$B/sf phase seal evaluate > $OUT/a008-1.txt 2>&1 & P1=$!; $B/sf phase seal evaluate > $OUT/a008-2.txt 2>&1 & P2=$!; wait $P1; E1=$?; wait $P2; E2=$?
echo "== seal 1 (exit $E1):"; cat $OUT/a008-1.txt; echo "== seal 2 (exit $E2):"; cat $OUT/a008-2.txt; state; echo "-- Record commits: $(git log --format=%s | grep -c 'Record c1 evaluate')"; git status --porcelain | grep -v soft-foundry/; $RB -ryaml -e 'puts YAML.load_file("changes/c1/metadata.yml").slice("status","current_phase").inspect'
echo "== 8b: a manual seal racing phase run's own seal: phase run evaluate with a fake shell that completes the handoff, while a manual seal fires 0.5 s later"
fresh a008b; hook 2; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "evaluate complete on disk"; PATH=/tmp/sf-attack2/fakebin:$PATH $B/sf phase run evaluate --shell claude > $OUT/a008b-run.txt 2>&1 & P1=$!; sleep 0.5; $B/sf phase seal evaluate > $OUT/a008b-seal.txt 2>&1; echo "manual seal exit $?"; wait $P1; echo "phase run exit $?"; echo "-- phase run output:"; cat $OUT/a008b-run.txt | grep -v '^  [✓-] '; echo "-- manual seal output:"; cat $OUT/a008b-seal.txt; state; echo "-- Record commits: $(git log --format=%s | grep -c 'Record c1 evaluate')"
} > $OUT/attack-008.txt 2>&1
# ---------- ATTACK-009: a held record lock
{
fresh a009; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"
LOCK=$($RB -I/Users/jscholen-iou/dev/soft_foundry/lib -rsoft_foundry/record_lock -e 'puts SoftFoundry::RecordLock.path(ARGV[0], "c1")' $R); echo "lock path: ${LOCK#$R/}"
mkdir -p $(dirname $LOCK); $RB -e 'f=File.open(ARGV[0], "a"); f.flock(File::LOCK_EX); STDERR.puts "holder: locked"; sleep 25' $LOCK & H=$!; sleep 0.5
echo "== 9a: phase seal evaluate while another process holds the lock (timed)"; /usr/bin/time -p $B/sf phase seal evaluate; echo "[exit $?]"; state
echo "== 9b: gate evaluate while the lock is held (reads take no lock?)"; /usr/bin/time -p $B/sf gate evaluate | grep -E 'PASS|FAIL|real'
echo "== 9c: phase reopen while the lock is held"; /usr/bin/time -p $B/sf phase reopen verify --reason "attack" 2>&1 | tail -3
kill $H 2>/dev/null; wait $H 2>/dev/null; echo "-- holder released; rerun seal:"; run $B/sf phase seal evaluate | tail -1
} > $OUT/attack-009.txt 2>&1
# ---------- ATTACK-010: a symlinked lock file, lock directory, and a lock that is a directory
{
fresh a010; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"
LOCK=$($RB -I/Users/jscholen-iou/dev/soft_foundry/lib -rsoft_foundry/record_lock -e 'puts SoftFoundry::RecordLock.path(ARGV[0], "c1")' $R); D=$(dirname $LOCK); mkdir -p $D
echo "== 10a: lock file is a symlink to changes/c1/metadata.yml"; cp changes/c1/metadata.yml /tmp/sf-attack2/repos/a010-meta-before.yml; ln -s $R/changes/c1/metadata.yml $LOCK; run $B/sf phase seal evaluate; cmp changes/c1/metadata.yml /tmp/sf-attack2/repos/a010-meta-before.yml && echo "metadata.yml unchanged"; state; rm $LOCK
echo "== 10b: lock file is a symlink to a file outside the repository (/etc/hosts)"; ln -s /etc/hosts $LOCK; run $B/sf phase seal evaluate; rm $LOCK
echo "== 10c: lock path is a directory"; mkdir $LOCK; run $B/sf phase seal evaluate; rmdir $LOCK
echo "== 10d: the locks directory is a symlink to /tmp"; rmdir $D; ln -s /tmp $D; run $B/sf phase seal evaluate; rm $D; mkdir -p $D
echo "== 10e: the locks directory is unwritable"; chmod 500 $D; run $B/sf phase seal evaluate; chmod 755 $D
echo "== 10f: a dangling symlink at the lock path"; ln -s /nonexistent/x.lock $LOCK; run $B/sf phase seal evaluate; rm $LOCK; echo "-- clean rerun:"; run $B/sf phase seal evaluate | tail -1
} > $OUT/attack-010.txt 2>&1
# ---------- ATTACK-013: --env value never printed by the parallel sealing path (real spawn, failing fake shell)
{
$RB $B/build.rb /tmp/sf-attack2/repos/a013 --through verify >/dev/null; cd /tmp/sf-attack2/repos/a013; R=$PWD
echo "== 13a: phase run evaluate attack --parallel --env SECRET=hunter2 --shell claude with a fake claude on PATH that exits 1"; PATH=/tmp/sf-attack2/fakebin:$PATH $B/sf phase run evaluate attack --parallel --env SECRET=hunter2 --shell claude > $OUT/a013-run.txt 2>&1; echo "[exit $?]"; echo "-- occurrences of hunter2 in the runner's output: $(grep -c hunter2 $OUT/a013-run.txt)"; grep -v '^  [✓-] ' $OUT/a013-run.txt; echo "-- fake shell log:"; cat $OUT/fake-claude.log
echo "== 13b: the fake shell is not executable (spawn fails): error path"; chmod -x /tmp/sf-attack2/fakebin/claude; PATH=/tmp/sf-attack2/fakebin $B/sf phase run evaluate attack --parallel --env SECRET=hunter2 --shell claude 2>&1 | grep -v '^  [✓-] ' | head -12; echo "-- occurrences of hunter2: $(PATH=/tmp/sf-attack2/fakebin $B/sf phase run evaluate attack --parallel --env SECRET=hunter2 --shell claude 2>&1 | grep -c hunter2)"; chmod +x /tmp/sf-attack2/fakebin/claude
echo "== 13c: --env given without NAME= (the whole text is a credential), given twice, with a NUL, and SOFT_FOUNDRY_ namespace"; for spec in 'hunter2' 'SECRET=a --env SECRET=b' 'SOFT_FOUNDRY_PHASE=attack' 'bad name=x'; do echo "-- --env $spec"; PATH=/tmp/sf-attack2/fakebin:$PATH $B/sf phase run evaluate attack --parallel --shell claude --env $spec 2>&1 | head -2; done
echo "== 13d: --dry-run names variables, not values"; PATH=/tmp/sf-attack2/fakebin:$PATH $B/sf phase run evaluate attack --parallel --env SECRET=hunter2 --shell claude --dry-run 2>&1 | grep -c hunter2; PATH=/tmp/sf-attack2/fakebin:$PATH $B/sf phase run evaluate attack --parallel --env SECRET=hunter2 --shell claude --dry-run 2>&1 | grep -i 'parallel:'
echo "== 13e: a value that is a substring of normal output ('phase'), to see what redaction does to the message"; PATH=/tmp/sf-attack2/fakebin $B/sf phase run evaluate attack --parallel --env SECRET=phase --shell claude 2>&1 | grep -v '^  [✓-] ' | head -6
} > $OUT/attack-013.txt 2>&1
# ---------- small checks: gate json flag; change summary session id with a stamp
{
cd /tmp/sf-attack2/repos/a019; echo "== gate usage"; $B/sf gate 2>&1 | head -6; echo "== gate all --json head"; $B/sf gate all --json 2>&1 | head -c 300; echo; echo "== gate review --json head"; $B/sf gate review --json 2>&1 | head -c 300; echo; echo "== change summary (review has a forged executed_by stamp)"; $B/sf change summary; echo "== change status advisories"; $B/sf change status 2>&1 | tail -6
} > $OUT/misc-json-summary.txt 2>&1
echo batch3 done
