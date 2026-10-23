# Fourth driver: probes the REV-001 remediation (Scope.tip_for with the evidence sha).
# Usage: ruby attack4.rb <checkout> > transcript4.txt
load File.join(__dir__, "attack_lib.rb")

case_ "ATTACK-020", "branch recorded before it exists, created at a commit that strictly follows the evidence, after code landed elsewhere (THREAT-001)"
dir = setup
sh(dir, *BIN, "change", "new", "a")
meta(dir, "a") { |m| m["scope"] = ["lib/a/**"]; m["git"]["branch"] = "frozen" }
commit(dir, "records, branch frozen recorded")
sha = head(dir); complete(dir, "a", sha); commit(dir, "phases complete")
sh(dir, "git", "branch", "frozen")            # the tip is a commit that strictly follows the evidence commit
touch(dir, "lib/a/x.rb"); commit(dir, "code lands on main after the branch is cut")
tests_yml(dir, "a", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => tree(dir, sha), "command" => "rake test", "outcome" => "passed" }, "checks" => [])
commit(dir, "tests")
puts "-- same shape as ATTACK-019 with the scope edited in the evidence commit, the one step the remediation says it cannot tell from a stacked branch"
pick(sf(dir, "gate", "verify", "--change", "a"), /06-verification  |evidence current/)

case_ "ATTACK-021", "control: change stacked under another; the record lives on its own branch while HEAD is a branch above it (legitimate)"
dir = setup
sh(dir, "git", "checkout", "-q", "-b", "stack")
sh(dir, *BIN, "change", "new", "a")
meta(dir, "a") { |m| m["scope"] = ["lib/a/**"]; m["git"]["branch"] = "stack" }
commit(dir, "records"); sha = head(dir); complete(dir, "a", sha); commit(dir, "phases complete")
sh(dir, "git", "checkout", "-q", "-b", "top")
touch(dir, "lib/a/x.rb"); commit(dir, "the change above, in scope")
puts "-- HEAD is top (above stack); the record's branch tip descends from the evidence commit, so it is the measure: in-scope code on top is not counted (by design: the change above covers its own code)"
pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current/)
sh(dir, "git", "checkout", "-q", "stack"); touch(dir, "lib/a/y.rb"); commit(dir, "commit on the record's own branch after the evidence")
sh(dir, "git", "checkout", "-q", "top")
puts "-- stack moved on after top was cut; the record's own branch is the measure and shows the in-scope commit"
pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current/)
