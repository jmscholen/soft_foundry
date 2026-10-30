. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
H=changes/c1/07-evaluation/handoff.yml
{
echo "== 6a: phase reopen evaluate, then hand-restore status complete, completed_at and the new commit_sha with no rerun, then phase seal"
fresh a027; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "evaluate complete on disk"; $B/sf phase seal evaluate | tail -1
echo "// code change" >> lib/app.rb; git commit -qam "change the code after evaluation"
run $B/sf phase reopen evaluate --reason "code changed after evaluate"
$RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["commit_sha"]=ARGV[1]; d["status"]="complete"; d["completed_at"]="2026-10-29T12:00:00Z"; File.write(p, YAML.dump(d))' $H $(git rev-parse HEAD)
run $B/sf phase seal evaluate; log; git log --format='%h %s' -n3
} > $OUT/attack-021b-reopen-rewrite.txt 2>&1
