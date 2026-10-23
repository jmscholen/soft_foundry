# Second attack driver: confirms the suspects the first pass raised, and drives the browser view.
# Usage: ruby attack2.rb <checkout> > transcript2.txt
load File.join(__dir__, "attack_lib.rb")

case_ "ATTACK-013", "rename out of an access-control or claimed path (THREAT-006, THREAT-003)"
puts "-- attack size when access-control code is renamed into the record's own scope"
dir = setup; with_records(dir, "a" => ["lib/a/**"])
sh(dir, "git", "mv", "lib/auth/f.rb", "lib/a/moved.rb"); commit(dir, "rename auth -> a")
puts "   raw diff as the tool reads it:"; puts sh(dir, "git", "diff", "--name-only", "-z", "HEAD~1", "HEAD", "--")[0].split("\0").map { |p| "     #{p}" }
sf(dir, "change", "size", "a", "--phase", "attack")
puts "-- same with the rename detection off (what the diff really contains)"
puts sh(dir, "git", "diff", "--name-only", "--no-renames", "HEAD~1", "HEAD")[0].lines.map { |l| "     #{l}" }
puts "-- verify staleness of a record that claims lib/auth/** when its code is renamed into another record's scope"
dir = setup; with_records(dir, "auth" => ["lib/auth/**"], "b" => ["lib/b/**"])
sh(dir, "git", "mv", "lib/auth/f.rb", "lib/b/moved.rb"); commit(dir, "rename auth -> b")
pick(sf(dir, "gate", "verify", "--change", "auth"), EV)
puts "-- same, plain delete of the file (no rename)"
dir = setup; with_records(dir, "auth" => ["lib/auth/**"], "b" => ["lib/b/**"])
sh(dir, "git", "rm", "-q", "lib/auth/f.rb"); commit(dir, "delete auth"); pick(sf(dir, "gate", "verify", "--change", "auth"), EV)
puts "-- same, but the record is unscoped (legacy path)"
dir = setup; with_records(dir, "u" => nil)
sh(dir, "git", "mv", "lib/auth/f.rb", "lib/b/moved.rb"); commit(dir, "rename"); pick(sf(dir, "gate", "verify", "--change", "u"), EV)

case_ "ATTACK-014", "repoint metadata git.branch to hide staleness (THREAT-001, THREAT-007)"
%w[scoped legacy].each do |kind|
  dir = setup; with_records(dir, "a" => (kind == "scoped" ? ["lib/a/**"] : nil))
  sh(dir, "git", "branch", "old-tip")
  touch(dir, "lib/a/x.rb"); commit(dir, "real code change")
  puts "-- #{kind} record: before the repoint"; pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current/)
  meta(dir, "a") { |m| m["git"]["branch"] = "old-tip" }; commit(dir, "repoint branch")
  puts "-- #{kind} record: after metadata git.branch = old-tip (a branch at the evidence commit)"; pick(sf(dir, "gate", "verify", "--change", "a"), /evidence current/)
end
puts "-- scoped: repoint plus a correct recorded size and run so that the entire verify gate passes"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); t = tree(dir, sha)
sh(dir, "git", "branch", "old-tip"); touch(dir, "lib/a/x.rb"); commit(dir, "real code change")
meta(dir, "a") { |m| m["git"]["branch"] = "old-tip" }
tests_yml(dir, "a", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => t, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
commit(dir, "repoint + tests"); out = sf(dir, "gate", "verify", "--change", "a"); pick(out, /06-verification|evidence current|check size|full-suite/)

case_ "ATTACK-015", "an active record declaring ** hides cross-record change (THREAT-003)"
dir = setup; sha = with_records(dir, "wide" => ["**"], "b" => ["lib/b/**"]); t = tree(dir, sha)
touch(dir, "lib/other/x.rb"); commit(dir, "code lands in lib/other")
puts "   wide is active (never closed). b records the size the gate demands and a passed run of the evidence tree"
tests_yml(dir, "b", "commit_sha" => sha, "size" => "full_at_verify", "full_suite" => { "tree" => t, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
commit(dir, "b tests"); out = sf(dir, "gate", "verify", "--change", "b"); pick(out, /06-verification|evidence current|check size|full-suite/)
puts "-- the same repository with wide closed: b goes stale"
meta(dir, "wide") { |m| m["status"] = "closed" }; commit(dir, "close wide"); pick(sf(dir, "gate", "verify", "--change", "b"), /06-verification|evidence current/)
puts "-- an active record with scope ** and an inactive-looking status value (abandoned, merged) still claims"
dir = setup; sha = with_records(dir, "wide" => ["**"], "b" => ["lib/b/**"])
meta(dir, "wide") { |m| m["status"] = "abandoned" }; commit(dir, "abandon wide"); touch(dir, "lib/other/x.rb"); commit(dir, "other"); pick(sf(dir, "gate", "verify", "--change", "b"), /evidence current/)

case_ "ATTACK-016", "case-folded citation slug (THREAT-009)"
dir = setup; sha = with_records(dir, "alpha" => ["lib/a/**"], "beta" => ["lib/b/**"]); t = tree(dir, sha)
tests_yml(dir, "alpha", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => t, "command" => "x", "outcome" => "passed" }, "checks" => [])
tests_yml(dir, "beta", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "cite" => "ALPHA" }, "checks" => [])
commit(dir, "cite ALPHA"); pick(sf(dir, "gate", "verify", "--change", "beta"), /full-suite/)
puts "   filesystem is case-insensitive here: #{File.exist?("#{dir}/CHANGES/alpha")}"

case_ "ATTACK-012", "markup in scope text; browser view (THREAT-012)"
require "net/http"; require "json"
dir = setup; with_records(dir, "a" => ["lib/a/**"])
evil = "lib/a/<img src=x onerror=alert(1)>.rb"
touch(dir, evil); commit(dir, "file with markup in its name")
meta(dir, "a") { |m| m["scope"] = [evil] }; commit(dir, "scope with markup")
pick(sf(dir, "check"), /scope|glob|fail|pass/i)
touch(dir, "lib/a/<b>second</b>.rb"); commit(dir, "second markup file")
rd, wr = IO.pipe
pid = spawn({ "NO_COLOR" => "1" }, *BIN, "ui", "--port", "0", chdir: dir, out: wr, err: wr); wr.close
line = nil
begin
  Timeout.timeout(20) { while (l = rd.gets); (line = l; break) if l =~ %r{http://127\.0\.0\.1:\d+/#token=}; end }
rescue Timeout::Error
end
if line
  line =~ %r{http://127\.0\.0\.1:(\d+)/#token=(\S+)}; port, token = $1, $2
  http = Net::HTTP.new("127.0.0.1", port.to_i)
  [["/api/change?slug=a", token], ["/api/change?slug=a", "wrong"], ["/api/change?slug=a", nil], ["/api/change?slug=..%2F..%2Fetc", token]].each do |path, tk|
    hdr = tk ? { "x-soft-foundry-token" => tk } : {}
    r = http.get(path, hdr); puts "GET #{path} (token #{tk.nil? ? 'none' : tk == token ? 'valid' : 'wrong'}) -> #{r.code} #{r['content-type']}"
    next unless r.code == "200"
    j = JSON.parse(r.body)
    puts "   scope field: #{j['scope'].inspect}"
    puts "   response headers nosniff/CSP: #{r['x-content-type-options'].inspect} / #{r['content-security-policy'].inspect}"
    gates = j["gates"].find { |g| g["phase"] == "verify" } || {}
    puts "   verify gate state words: #{gates.slice('status', 'state').inspect}"
  end
  r = http.get("/"); puts "GET / -> #{r.code}; CSP: #{r['content-security-policy'].inspect}"
else
  puts "   ui did not start: #{(rd.read_nonblock(2000) rescue '')}"
end
Process.kill("TERM", pid) rescue nil; Process.wait(pid) rescue nil
puts "   unsafe DOM sinks in app.js (innerHTML/insertAdjacentHTML/document.write/outerHTML/eval): #{File.read("#{REPO}/lib/soft_foundry/ui/assets/app.js").lines.grep(/innerHTML|insertAdjacentHTML|document\.write|outerHTML|\beval\(|new Function/).size}"
