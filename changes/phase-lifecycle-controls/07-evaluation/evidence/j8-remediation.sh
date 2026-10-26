. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
export NO_COLOR=1
echo "### EVAL-010 remediated defects: lock race, invisible characters, --env echo (AC-012, AC-021, AC-022, AC-029, AC-035)"
mk /tmp/evalrun/r1 c1 $ALL; cd /tmp/evalrun/r1
echo "--- invisible and direction-changing characters in --reason"
for cp in 200B 202E 2028 2029 FEFF; do
  printf "U+$cp: "; sf phase reopen evaluate --reason "$(printf "ok\\u$cp""end")" 2>&1 | cut -c1-200; echo "  exit=${PIPESTATUS[0]}"
done
OUTCOME=APPROVED mk /tmp/evalrun/r0 c1 $FIN; cd /tmp/evalrun/r0
printf "release item U+202E: "; sf change release c1 --item "A=$(printf 'x\u202Ey')" 2>&1 | cut -c1-200
printf "release id with U+200B: "; sf change release c1 --item "$(printf 'A\u200B')=desc" 2>&1 | cut -c1-200
echo "release refusals wrote: $(git status --porcelain | grep -v '^?? .soft-foundry' | wc -l) files"
sf change release c1 --item A=a >/dev/null 2>&1; git add -A; git commit -qm rel
printf "discharge note U+200B: "; sf change discharge A --note "$(printf 'x\u200By')" 2>&1 | cut -c1-200
cd /tmp/evalrun/r1
echo "records written by refusals: $(git status --porcelain | grep -v '^?? .soft-foundry' | wc -l)"
echo "--- accented text still accepted"
sf phase reopen evaluate --reason "révisé après l'écart"; echo "exit=$?"
echo "--- --env forms"
mk /tmp/evalrun/r2 c1 intake,discover,specify,threat_model,plan,implement,verify; cd /tmp/evalrun/r2
sf phase run evaluate attack --parallel --dry-run --env=FOO=bar 2>&1 | cut -c1-220; echo "exit=${PIPESTATUS[0]}"
SECRET='zz-credential-Qx9417-zz'
out=$(sf phase run evaluate attack --parallel --dry-run --env "$SECRET" 2>&1); echo "exit=$?"; echo "$out" | cut -c1-220
echo "secret echoed in output: $(echo "$out" | grep -c "$SECRET")"
out=$(sf phase run evaluate attack --parallel --dry-run --env "$SECRET=v" 2>&1); echo "exit=$?"; echo "$out" | cut -c1-220
echo "secret-as-name echoed: $(echo "$out" | grep -c "$SECRET")"
out=$(sf phase run evaluate attack --parallel --dry-run --env "good name=v" 2>&1); echo "exit=$?"; echo "$out" | cut -c1-220
out=$(sf phase run evaluate attack --parallel --dry-run --env "SOFT_FOUNDRY_X=v" 2>&1); echo "exit=$?"; echo "$out" | cut -c1-220
echo "--- valid --env still accepted"
sf phase run evaluate attack --parallel --dry-run --env DATABASE_URL=x_{phase} 2>&1 | head -6 | cut -c1-200; echo "exit=${PIPESTATUS[0]}"
echo "--- concurrent reopen (AC-029 lock): 6 at once on a complete record"
mk /tmp/evalrun/r3 c1 $ALL; cd /tmp/evalrun/r3
for i in 1 2 3 4 5 6; do ( sf phase reopen evaluate --reason "racer $i" > /tmp/evalrun/r3.$i 2>&1; echo "exit=$?" >> /tmp/evalrun/r3.$i ) & done; wait
cat /tmp/evalrun/r3.[1-6] | sort | uniq -c | sed 's/racer [0-9]//'
echo "phase_reopenings entries: $(grep -c '^- at:' <(sed -n '/^phase_reopenings/,/^[a-z_]*:/p' changes/c1/metadata.yml))"
ruby -ryaml -e 'm=YAML.unsafe_load_file("changes/c1/metadata.yml"); puts "entries=#{m["phase_reopenings"].size} metadata_parses=true"'
echo "--- concurrent release (6 at once): exactly one wins"
OUTCOME=APPROVED mk /tmp/evalrun/r4 c1 $FIN; cd /tmp/evalrun/r4
for i in 1 2 3 4 5 6; do ( sf change release c1 --item "I$i=item $i" > /tmp/evalrun/r4.$i 2>&1; echo "exit=$?" >> /tmp/evalrun/r4.$i ) & done; wait
grep -h '^exit=' /tmp/evalrun/r4.[1-6] | sort | uniq -c
ruby -ryaml -e 'm=YAML.unsafe_load_file("changes/c1/metadata.yml"); puts "status=#{m["status"]} items=#{m["release"]["items"].map{|i|i["id"]}.inspect}"'
cat /tmp/evalrun/r4.[1-6] | grep -v '^exit=\|^  ' | sed 's/I[0-9]//g' | cut -c1-200 | sort | uniq -c | head -6
echo "--- reopen racing release on a judged record"
OUTCOME=APPROVED mk /tmp/evalrun/r5 c1 $FIN; cd /tmp/evalrun/r5
( sf change release c1 --item A=a > /tmp/evalrun/r5.a 2>&1; echo "exit=$?" >> /tmp/evalrun/r5.a ) &
( sf phase reopen evaluate --reason race > /tmp/evalrun/r5.b 2>&1; echo "exit=$?" >> /tmp/evalrun/r5.b ) &
wait; cat /tmp/evalrun/r5.a /tmp/evalrun/r5.b | cut -c1-200
ruby -ryaml -e 'm=YAML.unsafe_load_file("changes/c1/metadata.yml"); puts "status=#{m["status"]} release=#{m["release"] ? "present" : "absent"} reopenings=#{(m["phase_reopenings"]||[]).size}"'
grep -h '^status:' changes/c1/*/handoff.yml | sort | uniq -c | tr '\n' ' '; echo
