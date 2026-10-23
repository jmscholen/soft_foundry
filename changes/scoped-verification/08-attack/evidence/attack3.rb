# Third driver: probes variants of the ATTACK-014 remediation (branch recorded before the evidence commit).
# Usage: ruby attack3.rb <checkout> > transcript3.txt
load File.join(__dir__, "attack_lib.rb")

case_ "ATTACK-017", "git.branch already repointed at the evidence commit (THREAT-001, THREAT-007)"
%w[scoped legacy].each do |kind|
  dir = setup
  %w[a].each { |s| sh(dir, *BIN, "change", "new", s) }
  meta(dir, "a") { |m| m["scope"] = ["lib/a/**"] } if kind == "scoped"
  meta(dir, "a") { |m| m["git"]["branch"] = "frozen" }
  commit(dir, "records, branch already recorded as frozen")
  sha = head(dir); sh(dir, "git", "branch", "frozen")
  complete(dir, "a", sha); commit(dir, "phases complete")
  touch(dir, "lib/a/x.rb"); commit(dir, "real code change after evidence on main")
  puts "-- #{kind}: branch frozen recorded in the evidence commit, branch tip = evidence commit, main moved on"
  pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current|check size/)
  puts "-- #{kind}: with recorded size and run, whole gate"
  t = tree(dir, sha)
  tests_yml(dir, "a", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => t, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
  commit(dir, "tests"); pick(sf(dir, "gate", "verify", "--change", "a"), /06-verification|evidence current|check size|full-suite/)
end

case_ "ATTACK-019", "git.branch recorded before the branch exists, branch created at the phases-complete commit afterwards (THREAT-001)"
%w[scoped legacy].each do |kind|
  dir = setup
  sh(dir, *BIN, "change", "new", "a")
  meta(dir, "a") { |m| m["scope"] = ["lib/a/**"] } if kind == "scoped"
  meta(dir, "a") { |m| m["git"]["branch"] = "frozen" }
  commit(dir, "records, branch recorded as frozen (no such branch yet: falls back to the worktree)")
  sha = head(dir); complete(dir, "a", sha); commit(dir, "phases complete")
  sh(dir, "git", "branch", "frozen")
  touch(dir, "lib/a/x.rb"); commit(dir, "real code change after evidence on main")
  t = tree(dir, sha)
  tests_yml(dir, "a", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => t, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
  commit(dir, "tests")
  puts "-- #{kind}: recorded size and run of the evidence tree; branch frozen created afterwards at the phases-complete commit"
  pick(sf(dir, "gate", "verify", "--change", "a"), /06-verification|evidence current|check size|full-suite/)
end

case_ "ATTACK-018", "git.branch edited to the checked-out branch name or blanked after evidence (THREAT-001)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
touch(dir, "lib/a/x.rb"); commit(dir, "code")
meta(dir, "a") { |m| m["git"].delete("branch") }; commit(dir, "delete git.branch")
pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current/)
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
touch(dir, "lib/a/x.rb"); commit(dir, "code")
meta(dir, "a") { |m| m["git"] = "x" }; commit(dir, "git scalar")
pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current|error|fail/)
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
touch(dir, "lib/a/x.rb"); commit(dir, "code")
sh(dir, "git", "branch", "ev", sha); meta(dir, "a") { |m| m["git"]["branch"] = "ev" }; commit(dir, "repoint then revert in one go")
meta(dir, "a") { |m| m["git"]["branch"] = "main" }; commit(dir, "revert to main")
puts "-- repoint then revert to the original value: evidence is rightly stale from the code change"
pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current/)
