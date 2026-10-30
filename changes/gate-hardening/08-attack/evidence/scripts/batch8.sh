. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
H=changes/c1/07-evaluation/handoff.yml
rewrite() { $RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["commit_sha"]=ARGV[1]; File.write(p, YAML.dump(d))' $H "$1"; }
{
echo "== 8a: reopen, restore status/completed_at/new commit_sha by hand, append ONE newline to results.md, seal (ATK-011 structure-only boundary)"
fresh a040; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "evaluate complete on disk"; $B/sf phase seal evaluate | tail -1
echo "// code change" >> lib/app.rb; git commit -qam "change the code after evaluation"
run $B/sf phase reopen evaluate --reason "code changed after evaluate"
$RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["commit_sha"]=ARGV[1]; d["status"]="complete"; d["completed_at"]="2026-10-29T12:00:00Z"; File.write(p, YAML.dump(d))' $H $(git rev-parse HEAD)
printf '\n' >> changes/c1/07-evaluation/results.md
run $B/sf phase seal evaluate; log
echo "-- evidence content identical apart from one trailing newline in results.md:"; git diff HEAD~1 --stat -- changes/c1/07-evaluation | tail -3
echo "== 8b: guard mode spellings in enforcement.yml"
for body in 'guard: {mode: blokc}' 'guard: {mode: BLOCK}' 'guard: {mode: "block "}' 'guard: block' 'mode: block' 'guard: {}' 'guard: {mode: block}'; do
  fresh a041; printf 'version: 1\n%s\n' "$body" > .ai/policies/enforcement.yml; git add -A; git commit -qm pol
  echo "-- $body"; $B/sf check 2>&1 | grep -iE 'enforcement|guard' | head -3; $B/complete.rb $R evaluate HEAD >/dev/null --no-runner; git add -A; git commit -qm c; $B/sf gate evaluate 2>&1 | grep -iE 'fresh session'
done
} > $OUT/attack-024-ledger.txt 2>&1
