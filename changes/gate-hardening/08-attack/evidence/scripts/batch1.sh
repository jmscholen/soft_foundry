. /tmp/sf-attack2/bin/lib.sh
# ---------- ATTACK-001: seal from a session whose SOFT_FOUNDRY_PHASE names another phase
{
fresh a001; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"; echo "HEAD $(git rev-parse --short HEAD)"
echo "== 1a: SOFT_FOUNDRY_PHASE=implement seals evaluate"; run env SOFT_FOUNDRY_PHASE=implement $B/sf-env phase seal evaluate; log
echo "== 1b: SOFT_FOUNDRY_PHASE=verify (predecessor) seals evaluate"; run env SOFT_FOUNDRY_PHASE=verify $B/sf-env phase seal evaluate; log
echo "== 1c: SOFT_FOUNDRY_PHASE='evaluate ' (trailing space) seals evaluate"; run env "SOFT_FOUNDRY_PHASE=evaluate " $B/sf-env phase seal evaluate; log
echo "== 1d: SOFT_FOUNDRY_PHASE=Evaluate (case) seals evaluate"; run env SOFT_FOUNDRY_PHASE=Evaluate $B/sf-env phase seal evaluate; log
echo "== 1e: SOFT_FOUNDRY_PHASE= (empty: the accepted residual, a shell that unset it) seals evaluate"; run env SOFT_FOUNDRY_PHASE= $B/sf-env phase seal evaluate; log
} > $OUT/attack-001.txt 2>&1
# ---------- ATTACK-002: handoff.yml is a symlink to another phase's handoff
{
fresh a002; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"
rm changes/c1/07-evaluation/handoff.yml; ln -s ../06-verification/handoff.yml changes/c1/07-evaluation/handoff.yml; ls -l changes/c1/07-evaluation/handoff.yml
echo "== 2a: phase seal evaluate"; run $B/sf phase seal evaluate; log
echo "== 2b: gate evaluate"; run $B/sf gate evaluate
echo "== 2c: change summary"; run $B/sf change summary
echo "== 2d: change status"; run $B/sf change status
echo "== 2e: symlink to a file outside the repository (/etc/hosts)"; rm changes/c1/07-evaluation/handoff.yml; ln -s /etc/hosts changes/c1/07-evaluation/handoff.yml; run $B/sf phase seal evaluate; run $B/sf gate evaluate
echo "== 2f: dangling symlink"; rm changes/c1/07-evaluation/handoff.yml; ln -s /nonexistent/handoff.yml changes/c1/07-evaluation/handoff.yml; run $B/sf phase seal evaluate; run $B/sf gate evaluate; run $B/sf change summary
echo "== 2g: the whole phase directory is a symlink to 06-verification"; rm changes/c1/07-evaluation/handoff.yml; rm -rf changes/c1/07-evaluation; ln -s 06-verification changes/c1/07-evaluation; run $B/sf phase seal evaluate; run $B/sf gate evaluate; log
} > $OUT/attack-002.txt 2>&1
# ---------- ATTACK-003: metadata.yml is a symlink
{
fresh a003; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"
cp changes/c1/metadata.yml /tmp/sf-attack2/repos/a003-metadata-elsewhere.yml; rm changes/c1/metadata.yml; ln -s /tmp/sf-attack2/repos/a003-metadata-elsewhere.yml changes/c1/metadata.yml; ls -l changes/c1/metadata.yml
echo "== 3a: phase seal evaluate"; run $B/sf phase seal evaluate; log
echo "== 3b: gate evaluate"; run $B/sf gate evaluate
echo "== 3c: change summary"; run $B/sf change summary
echo "== 3d: change status"; run $B/sf change status
echo "== 3e: gate all"; run $B/sf gate all
echo "== 3f: ci"; run $B/sf ci
} > $OUT/attack-003.txt 2>&1
# ---------- ATTACK-014: seal --change c1 from a branch that is not the record's
{
fresh a014; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"
git checkout -qb other; echo "on $(git branch --show-current)"
echo "== 14a: phase seal evaluate --change c1 from branch other (record branch change/c1 exists)"; run $B/sf phase seal evaluate --change c1; log
echo "== 14b: same from a detached HEAD"; git checkout -q --detach; run $B/sf phase seal evaluate --change c1; git checkout -q other
echo "== 14c: record branch deleted: the branch does not exist, does the seal say so?"; git branch -D change/c1; run $B/sf phase seal evaluate --change c1; log; git log --format='%h %s %D' -n 3
echo "== 14d: the record branch now exists only as origin/change/c1 (a remote-tracking ref) at an older commit"; fresh a014b; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"; git update-ref refs/remotes/origin/change/c1 HEAD~1; git checkout -qb other; git branch -D change/c1; run $B/sf phase seal evaluate --change c1; log
} > $OUT/attack-014.txt 2>&1
# ---------- ATTACK-018: metadata git: a string / a list / missing
{
fresh a018; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"
for v in 'git: a string' 'git: []' 'git:' 'git: 7'; do
  cp $T/changes/c1/metadata.yml changes/c1/metadata.yml
  perl -0pi -e "s/^git:\n(  .*\n)+/$v\n/m" changes/c1/metadata.yml; echo "== 18: metadata.yml with [$v]"; grep -n '^git' changes/c1/metadata.yml
  run $B/sf phase seal evaluate; run $B/sf gate evaluate; run $B/sf change summary; run $B/sf change status; run $B/sf gate all 
done
echo "== 18e: metadata.yml git.branch is a list"; cp $T/changes/c1/metadata.yml changes/c1/metadata.yml; perl -0pi -e 's/^  branch: .*$/  branch: [a, b]/m' changes/c1/metadata.yml; grep -n -A2 '^git' changes/c1/metadata.yml; run $B/sf phase seal evaluate; run $B/sf gate evaluate
echo "== 18f: metadata.yml does not parse"; printf 'change: {\n' > changes/c1/metadata.yml; run $B/sf phase seal evaluate; run $B/sf gate evaluate; run $B/sf change summary; run $B/sf ci
} > $OUT/attack-018.txt 2>&1
# ---------- extras on the seal entry
{
fresh ax1; $B/complete.rb $R evaluate HEAD; git add -A; git commit -qm "evaluate complete on disk"
echo "== X1a: planted metadata.yml.soft-foundry-tmp sibling"; echo planted > changes/c1/metadata.yml.soft-foundry-tmp; run $B/sf phase seal evaluate; log; rm changes/c1/metadata.yml.soft-foundry-tmp
echo "== X1b: planted handoff.yml.soft-foundry-tmp as a symlink to metadata.yml"; ln -s ../metadata.yml changes/c1/07-evaluation/handoff.yml.soft-foundry-tmp; run $B/sf phase seal evaluate; log; rm changes/c1/07-evaluation/handoff.yml.soft-foundry-tmp
echo "== X1c: --change with a traversal slug"; run $B/sf phase seal evaluate --change ../c1; run $B/sf phase seal evaluate --change 'c1/../../etc'; run $B/sf phase seal 'evaluate;id'
echo "== X1d: handoff status 'Complete' and 'complete ' (not the word)"; perl -pi -e 's/^status: complete$/status: Complete/' changes/c1/07-evaluation/handoff.yml; run $B/sf phase seal evaluate; perl -pi -e 's/^status: Complete$/status: "complete "/' changes/c1/07-evaluation/handoff.yml; run $B/sf phase seal evaluate; perl -pi -e 's/^status: "complete "$/status: complete/' changes/c1/07-evaluation/handoff.yml
echo "== X1e: a hand edit to metadata.yml (skipped_phases, risk) rides into the seal commit"; perl -pi -e 's/^risk: .*$/risk: low/; s/^skipped_phases: \[\]$/skipped_phases: [{phase: attack, rationale: smuggled in the seal commit}]/' changes/c1/metadata.yml; git diff --stat; run $B/sf phase seal evaluate; log; git show --stat HEAD | tail -5; git show HEAD -- changes/c1/metadata.yml | grep '^[-+]' | grep -v '^[-+][-+]'
echo "== X1f: seal again (already sealed path)"; run $B/sf phase seal evaluate
echo "== X1g: dirty lib/ after seal: seal attack with uncommitted code"; $B/complete.rb $R attack HEAD; echo 'puts 2' > lib/app.rb; run $B/sf phase seal attack; git checkout lib/app.rb; echo "== X1h: ignored-but-present code path"; echo 'lib/secret.rb' > .gitignore; echo x > lib/secret.rb; run $B/sf phase seal attack; rm lib/secret.rb .gitignore
echo "== X1i: untracked file under a directory the globs cover (test/)"; mkdir -p test; echo x > test/planted_test.rb; run $B/sf phase seal attack; rm -rf test
} > $OUT/extras-seal-entry.txt 2>&1
echo done
