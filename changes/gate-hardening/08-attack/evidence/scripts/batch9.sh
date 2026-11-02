. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
{
echo "== 9a: block-mode misspellings of the policy shape vs the fresh-session check on review (completed without executed_by)"
for body in 'mode: block' 'guard: block' 'guard: {}' 'guard: {mode: block}'; do
  $RB $B/build.rb /tmp/sf-attack2/repos/a050 --through attack >/dev/null; cd /tmp/sf-attack2/repos/a050; R=$PWD
  printf 'version: 1\n%s\n' "$body" > .ai/policies/enforcement.yml; $B/complete.rb $R review HEAD --no-runner >/dev/null
  echo "-- $body"; $B/sf check 2>&1 | grep -iE 'enforcement' | head -2; $B/sf gate review 2>&1 | grep -iE 'fresh session'
done
} > $OUT/attack-025-policy-shape.txt 2>&1
