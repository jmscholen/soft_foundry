# Attack driver for scoped-verification. Builds throwaway git repositories in
# the system temp directory (copy of this checkout's .ai/) and drives the real
# CLI against them. Nothing outside those directories is touched.
# Usage: ruby attack.rb <checkout> > transcript.txt
require "tmpdir"; require "fileutils"; require "open3"; require "yaml"; require "date"; require "timeout"
REPO = File.expand_path(ARGV.fetch(0))
BIN = ["ruby", "-I#{REPO}/lib", "#{REPO}/exe/soft-foundry"]
def sh(dir, *c) = Open3.capture2e(*c, chdir: dir)
def sf(dir, *a, env: {})
  out, st = Open3.capture2e({ "NO_COLOR" => "1" }.merge(env), *BIN, *a, chdir: dir)
  puts "$ soft-foundry #{a.join(' ')}"
  puts out.lines.map { |l| "  #{l}" }.join
  puts "  [exit #{st.exitstatus}]"
  out
end
def commit(dir, m) = (sh(dir, "git", "add", "-A"); sh(dir, "git", "commit", "-q", "-m", m))
def head(dir) = sh(dir, "git", "rev-parse", "HEAD")[0].strip
def tree(dir, sha) = sh(dir, "git", "rev-parse", "#{sha}^{tree}")[0].strip
def touch(dir, rel, body = "puts #{rand(10**6)}\n") = (FileUtils.mkdir_p(File.dirname(File.join(dir, rel))); File.write(File.join(dir, rel), body))
def complete(dir, slug, sha)
  Dir.glob("#{dir}/changes/#{slug}/*/").each do |pd|
    Dir.glob("**/*", base: pd).each { |r| p = File.join(pd, r); File.write(p, File.read(p).gsub(/\bTBD\b/, "done")) if File.file?(p) }
    next unless (1..8).cover?(File.basename(pd)[0, 2].to_i)
    h = File.join(pd, "handoff.yml"); d = YAML.safe_load_file(h)
    d.merge!("status" => "complete", "commit_sha" => sha, "completed_at" => "2026-09-09T00:00:00Z"); File.write(h, YAML.dump(d))
  end
end
def meta(dir, slug) = (p = File.join(dir, "changes", slug, "metadata.yml"); d = YAML.safe_load_file(p, permitted_classes: [Time, Date]); yield d; File.write(p, YAML.dump(d)))
def profile(dir, extra) = File.open("#{dir}/.ai/repository.yml", "a") { |f| f.puts extra }
def setup(core: ["lib/base/**"], access: ["lib/auth/**"])
  dir = Dir.mktmpdir("sf-attack"); FileUtils.cp_r("#{REPO}/.ai", dir)
  File.write("#{dir}/AGENTS.md", "# agents\n")
  %w[a b base other auth].each { |d| touch(dir, "lib/#{d}/f.rb", "puts '#{d}'\n") }
  profile(dir, "shared_core:\n#{core.map { |g| "  - #{g}" }.join("\n")}") if core
  profile(dir, "access_control:\n#{access.map { |g| "  - #{g}" }.join("\n")}") if access
  sh(dir, "git", "init", "-q", "-b", "main"); sh(dir, "git", "config", "user.email", "e@x"); sh(dir, "git", "config", "user.name", "E"); commit(dir, "initial")
  dir
end
# Records with evidence complete at one commit.
def with_records(dir, scopes)
  scopes.each_key { |s| sh(dir, *BIN, "change", "new", s) }
  scopes.each { |s, sc| meta(dir, s) { |m| m["scope"] = sc } unless sc.nil? }
  commit(dir, "records"); sha = head(dir)
  scopes.each_key { |s| complete(dir, s, sha) }; commit(dir, "phases complete")
  sha
end
def tests_yml(dir, slug, data) = File.write("#{dir}/changes/#{slug}/06-verification/tests.yml", YAML.dump(data))
def pick(out, pat) = puts(out.lines.grep(pat).map { |l| "    >> #{l.strip}" })
def case_(id, title) = puts("\n##### #{id}: #{title}")
EV = /evidence current|declaration|full-suite|check size|STALE|fail|refus/i

case_ "ATTACK-001", "narrow the declarations after the evidence (THREAT-001)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**", "lib/b/**"])
puts "-- baseline: change in lib/b stales a"
touch(dir, "lib/b/x.rb"); commit(dir, "b change"); pick(sf(dir, "gate", "verify", "--change", "a"), EV)
puts "-- attack 1a: same commit narrows a's scope AND changes lib/b"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**", "lib/b/**"])
meta(dir, "a") { |m| m["scope"] = ["lib/a/**"] }; touch(dir, "lib/b/x.rb"); commit(dir, "narrow + change"); pick(sf(dir, "gate", "verify", "--change", "a"), EV)
puts "-- attack 1b: remove scope entirely (whole-repository) then change code"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
meta(dir, "a") { |m| m.delete("scope") }; touch(dir, "lib/a/x.rb"); commit(dir, "unscope + change"); pick(sf(dir, "gate", "verify", "--change", "a"), EV)
puts "-- attack 1c: remove shared_core from the profile, then change lib/base"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
File.write("#{dir}/.ai/repository.yml", File.read("#{dir}/.ai/repository.yml").sub(/shared_core:\n  - lib\/base\/\*\*\n/, "")); touch(dir, "lib/base/x.rb"); commit(dir, "drop core + change"); pick(sf(dir, "gate", "verify", "--change", "a"), EV)
puts "-- attack 1d: remove access_control from the profile (declaration edit must stale)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
File.write("#{dir}/.ai/repository.yml", File.read("#{dir}/.ai/repository.yml").sub(/access_control:\n  - lib\/auth\/\*\*\n/, "")); commit(dir, "drop access control"); pick(sf(dir, "gate", "verify", "--change", "a"), EV)
puts "-- attack 1e: flip the attack sizes in the check-sizing policy after evidence (scoped record)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
pol = "#{dir}/.ai/policies/check-sizing.yml"
File.write(pol, File.read(pol).sub("attack: [touched_doors_plus_smoke, full_route_sweep]", "attack: [full_route_sweep, touched_doors_plus_smoke]")); commit(dir, "flip attack sizes"); pick(sf(dir, "gate", "verify", "--change", "a"), EV)
puts "-- attack 1f: same edit against an UNSCOPED record (legacy behaviour)"
dir = setup; sha = with_records(dir, "u" => nil)
pol = "#{dir}/.ai/policies/check-sizing.yml"
File.write(pol, File.read(pol).sub("attack: [touched_doors_plus_smoke, full_route_sweep]", "attack: [full_route_sweep, touched_doors_plus_smoke]")); commit(dir, "flip attack sizes"); pick(sf(dir, "gate", "verify", "--change", "u"), EV)
sf(dir, "change", "size", "u", "--phase", "attack")

case_ "ATTACK-002", "blind or hostile declarations (THREAT-002, THREAT-009)"
bad = { "empty" => [""], "blank" => ["   "], "absolute" => ["/etc/**"], "dotdot" => ["lib/../.ai/**"], "dash" => ["--output=x"], "newline" => ["lib/a/**\nlib/b/**"], "nul" => ["lib/a\u0000/**"], "nomatch" => ["nothing/**"], "nonstring" => [{ "x" => 1 }], "string-not-list" => "lib/**", "too-many-groups" => ["{a,b}/{a,b}/{a,b}/{a,b}/{a,b}/{a,b}/{a,b}/**"], "long" => ["l" * 300] }
bad.each do |name, scope|
  dir = setup; sh(dir, *BIN, "change", "new", "a"); meta(dir, "a") { |m| m["scope"] = scope }; commit(dir, "r")
  puts "-- scope #{name}"; pick(sf(dir, "check"), /fail|scope|glob/i)
end
puts "-- shared_core matching only docs (non-code)"
dir = setup(core: ["docs/**"]); touch(dir, "docs/x.md", "x\n"); commit(dir, "docs"); pick(sf(dir, "check"), /fail|shared_core/i)
puts "-- shared_core: ['**'] (matches everything incl. non-code; allowed?)"
dir = setup(core: ["**"]); pick(sf(dir, "check"), /fail|shared_core|pass/i)
puts "-- shared_core blind (matches nothing)"
dir = setup(core: ["nope/**"]); pick(sf(dir, "check"), /fail|shared_core/i)
puts "-- hostile glob on shared_core with .."
dir = setup(core: ["'lib/../**'"]); pick(sf(dir, "check"), /fail|shared_core/i)
puts "-- gate itself (not just check) with a blind scope after evidence"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
meta(dir, "a") { |m| m["scope"] = ["lib/a/../b/**"] }; commit(dir, "dotdot scope"); pick(sf(dir, "gate", "verify", "--change", "a"), EV)

case_ "ATTACK-003", "cross-record scope abuse (THREAT-003)"
puts "-- closed record keeps scope ** ; active record b in lib/b; code lands in lib/other"
dir = setup; sha = with_records(dir, "wide" => ["**"], "b" => ["lib/b/**"])
meta(dir, "wide") { |m| m["status"] = "closed" }; commit(dir, "close wide")
touch(dir, "lib/other/x.rb"); commit(dir, "other"); pick(sf(dir, "gate", "verify", "--change", "b"), EV)
puts "-- same, but wide is ACTIVE (claims everything): lib/other is claimed by wide, so b stays current"
dir = setup; sha = with_records(dir, "wide" => ["**"], "b" => ["lib/b/**"])
touch(dir, "lib/other/x.rb"); commit(dir, "other"); pick(sf(dir, "gate", "verify", "--change", "b"), EV)
pick(sf(dir, "change", "status", "b"), /advis|overlap|scope|warn/i)
puts "-- malformed sibling scope (absolute glob) claims nothing"
dir = setup; sha = with_records(dir, "bad" => ["lib/a/**"], "b" => ["lib/b/**"])
meta(dir, "bad") { |m| m["scope"] = ["/**"] }; commit(dir, "bad sib"); touch(dir, "lib/other/x.rb"); commit(dir, "other"); pick(sf(dir, "gate", "verify", "--change", "b"), EV)
puts "-- overlapping scopes: each assumes the other owns lib/a"
dir = setup; sha = with_records(dir, "x" => ["lib/a/**"], "y" => ["lib/a/**", "lib/b/**"])
touch(dir, "lib/a/n.rb"); commit(dir, "a"); %w[x y].each { |s| pick(sf(dir, "gate", "verify", "--change", s), EV) }
puts "-- sibling with unreadable YAML claims nothing"
File.write("#{dir}/changes/x/metadata.yml", "scope: [unterminated\n"); commit(dir, "break x"); touch(dir, "lib/other/z.rb"); commit(dir, "other2"); pick(sf(dir, "gate", "verify", "--change", "y"), EV)

case_ "ATTACK-004", "forged and abusive full-suite records (THREAT-004, THREAT-008, THREAT-009)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"], "b" => ["lib/b/**"]); t = tree(dir, sha)
FS = /full-suite|check size/
tryit = lambda do |label, slug, data|
  puts "-- #{label}"; tests_yml(dir, slug, data); commit(dir, label); pick(sf(dir, "gate", "verify", "--change", slug), FS)
end
base = { "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "checks" => [] }
tryit.("typed tree+outcome without any run (residual: a claim)", "a", base.merge("full_suite" => { "tree" => t, "command" => "echo", "outcome" => "passed" }))
tryit.("outcome Passed (case)", "a", base.merge("full_suite" => { "tree" => t, "command" => "x", "outcome" => "Passed" }))
tryit.("outcome with trailing space", "a", base.merge("full_suite" => { "tree" => t, "command" => "x", "outcome" => "passed " }))
tryit.("outcome boolean true", "a", base.merge("full_suite" => { "tree" => t, "command" => "x", "outcome" => true }))
tryit.("tree abbreviated", "a", base.merge("full_suite" => { "tree" => t[0, 12], "command" => "x", "outcome" => "passed" }))
tryit.("tree uppercase", "a", base.merge("full_suite" => { "tree" => t.upcase, "command" => "x", "outcome" => "passed" }))
tryit.("full_suite is a list", "a", base.merge("full_suite" => [{ "tree" => t }]))
tryit.("full_suite is a string", "a", base.merge("full_suite" => "passed"))
tryit.("cite AND tree both present", "a", base.merge("full_suite" => { "cite" => "a", "tree" => t, "command" => "x", "outcome" => "passed" }))
tryit.("self citation", "a", base.merge("full_suite" => { "cite" => "a" }))
tests_yml(dir, "b", base.merge("full_suite" => { "cite" => "a" })); commit(dir, "loop b->a")
tryit.("citation loop a->b->a (b cites a)", "a", base.merge("full_suite" => { "cite" => "b" }))
tests_yml(dir, "b", base.merge("full_suite" => { "tree" => t, "command" => "x", "outcome" => "failed" })); commit(dir, "b failed")
tryit.("cite a record with outcome failed", "a", base.merge("full_suite" => { "cite" => "b" }))
["../b", "-x", "a/b", "a\nb", ".hidden", "./b", "b/", "B"].each { |s| tryit.("cite slug #{s.inspect}", "a", base.merge("full_suite" => { "cite" => s })) }
tryit.("cite integer", "a", base.merge("full_suite" => { "cite" => 5 }))
tryit.("cite nil", "a", base.merge("full_suite" => { "cite" => nil }))
puts "-- cite a record that is a symlink to a directory outside the repository"
out = Dir.mktmpdir("sf-outside"); FileUtils.mkdir_p("#{out}/06-verification")
File.write("#{out}/06-verification/tests.yml", YAML.dump("full_suite" => { "tree" => t, "command" => "x", "outcome" => "passed" }))
File.symlink(out, "#{dir}/changes/evil"); commit(dir, "evil symlink")
tryit.("cite evil (symlink out of tree)", "a", base.merge("full_suite" => { "cite" => "evil" }))
puts "-- cited tests.yml uses YAML alias / ruby tag"
File.write("#{dir}/changes/b/06-verification/tests.yml", "full_suite: &x\n  tree: #{t}\n  command: x\n  outcome: passed\nother: *x\n"); commit(dir, "alias")
tryit.("cite b whose tests.yml has an alias", "a", base.merge("full_suite" => { "cite" => "b" }))
File.write("#{dir}/changes/b/06-verification/tests.yml", "full_suite: !ruby/object:OpenStruct\n  tree: #{t}\n"); commit(dir, "tag")
tryit.("cite b whose tests.yml has a ruby tag", "a", base.merge("full_suite" => { "cite" => "b" }))
puts "-- tests.yml of the citing record itself holds an alias"
File.write("#{dir}/changes/a/06-verification/tests.yml", "x: &y {tree: #{t}}\nfull_suite: *y\n"); commit(dir, "own alias"); pick(sf(dir, "gate", "verify", "--change", "a"), /full-suite|check size|alias|fail|rror/i)
puts "-- replay after history rewrite: handoff rebound to a newer commit while tests.yml keeps the old tree"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); t = tree(dir, sha)
tests_yml(dir, "a", base.merge("commit_sha" => sha, "full_suite" => { "tree" => t, "command" => "x", "outcome" => "passed" })); commit(dir, "a ok")
touch(dir, "lib/a/new.rb"); commit(dir, "code"); sha2 = head(dir)
h = "#{dir}/changes/a/06-verification/handoff.yml"; d = YAML.safe_load_file(h); d["commit_sha"] = sha2; File.write(h, YAML.dump(d)); commit(dir, "rebind to new commit")
pick(sf(dir, "gate", "verify", "--change", "a"), FS)
puts "-- short commit_sha in the handoff"
d["commit_sha"] = sha2[0, 7]; File.write(h, YAML.dump(d)); commit(dir, "short sha"); pick(sf(dir, "gate", "verify", "--change", "a"), FS)

case_ "ATTACK-005", "reuse over untracked, ignored and dirty files (THREAT-005)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"], "b" => ["lib/b/**"]); t = tree(dir, sha)
tests_yml(dir, "a", base.merge("commit_sha" => sha, "full_suite" => { "tree" => t, "command" => "x", "outcome" => "passed" }))
tests_yml(dir, "b", base.merge("commit_sha" => sha, "full_suite" => { "cite" => "a" })); commit(dir, "runs")
puts "-- clean"; pick(sf(dir, "gate", "verify", "--change", "b"), FS)
puts "-- untracked lib file"; touch(dir, "lib/a/u.rb"); pick(sf(dir, "gate", "verify", "--change", "b"), FS); File.delete("#{dir}/lib/a/u.rb")
puts "-- ignored lib file"; File.write("#{dir}/.gitignore", "lib/a/ign.rb\n"); commit(dir, "ignore"); touch(dir, "lib/a/ign.rb"); pick(sf(dir, "gate", "verify", "--change", "b"), FS); File.delete("#{dir}/lib/a/ign.rb")
puts "-- ignored non-code file changes behaviour but is outside code paths (documented residual)"
File.write("#{dir}/.gitignore", "lib/a/ign.rb\nconfig.local\n"); commit(dir, "ignore2"); touch(dir, "config.local", "X=1\n"); pick(sf(dir, "gate", "verify", "--change", "b"), FS); File.delete("#{dir}/config.local")
puts "-- staged but uncommitted modification of a tracked code file"
File.write("#{dir}/lib/a/f.rb", "puts 'evil'\n"); sh(dir, "git", "add", "lib/a/f.rb"); pick(sf(dir, "gate", "verify", "--change", "b"), FS); sh(dir, "git", "reset", "-q", "--hard")
puts "-- deleted tracked code file"
File.delete("#{dir}/lib/a/f.rb"); pick(sf(dir, "gate", "verify", "--change", "b"), FS); sh(dir, "git", "checkout", "-q", "--", ".")
puts "-- untracked name with space, unicode, leading dash under lib"
touch(dir, "lib/a/-weird name é.rb"); pick(sf(dir, "gate", "verify", "--change", "b"), FS); FileUtils.rm_f(Dir.glob("#{dir}/lib/a/-weird*"))
puts "-- renamed (staged) code file"
sh(dir, "git", "mv", "lib/a/f.rb", "lib/a/g.rb"); pick(sf(dir, "gate", "verify", "--change", "b"), FS); sh(dir, "git", "reset", "-q", "--hard")

case_ "ATTACK-006", "undersized checks (THREAT-006)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); t = tree(dir, sha)
good = { "commit_sha" => sha, "full_suite" => { "tree" => t, "command" => "x", "outcome" => "passed" }, "checks" => [] }
sizeit = lambda do |label, data|
  puts "-- #{label}"; tests_yml(dir, "a", data); commit(dir, label); pick(sf(dir, "gate", "verify", "--change", "a"), /check size|full-suite/)
end
touch(dir, "lib/base/x.rb"); commit(dir, "core change")
sf(dir, "change", "size", "a", "--phase", "verify")
sizeit.("claims targeted although shared core changed", good.merge("size" => "targeted_plus_full_before_merge"))
sizeit.("size missing", good)
sizeit.("size unknown name", good.merge("size" => "nothing"))
sizeit.("size is a list", good.merge("size" => ["full_at_verify"]))
sizeit.("size has different case", good.merge("size" => "FULL_AT_VERIFY"))
sizeit.("size correct", good.merge("size" => "full_at_verify"))
puts "-- full_at_verify computed but no full_suite recorded"
tests_yml(dir, "a", { "commit_sha" => sha, "size" => "full_at_verify", "checks" => [] }); commit(dir, "no suite"); pick(sf(dir, "gate", "verify", "--change", "a"), /check size|full-suite/)
puts "-- scope omits touched paths: a declares lib/a; change in lib/other is unclaimed -> full"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); touch(dir, "lib/other/x.rb"); commit(dir, "other"); sf(dir, "change", "size", "a", "--phase", "verify")
puts "-- attack size: access_control undeclared"
dir = setup(access: nil); sha = with_records(dir, "a" => ["lib/a/**"]); touch(dir, "lib/a/x.rb"); commit(dir, "a"); sf(dir, "change", "size", "a", "--phase", "attack")
puts "-- attack size: declared, only lib/a touched, then lib/auth touched"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); touch(dir, "lib/a/x.rb"); commit(dir, "a"); sf(dir, "change", "size", "a", "--phase", "attack")
touch(dir, "lib/auth/login.rb"); commit(dir, "auth"); sf(dir, "change", "size", "a", "--phase", "attack")
puts "-- move auth code into a's scope (rename)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); FileUtils.mkdir_p("#{dir}/lib/a"); sh(dir, "git", "mv", "lib/auth/f.rb", "lib/a/moved.rb"); commit(dir, "move auth code into a"); sf(dir, "change", "size", "a", "--phase", "attack")
puts "-- symlink inside a's scope pointing at auth code"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); FileUtils.mkdir_p("#{dir}/lib/a"); File.symlink("../auth/f.rb", "#{dir}/lib/a/link.rb"); commit(dir, "symlink to auth"); sf(dir, "change", "size", "a", "--phase", "attack")
puts "-- gate attack with a recorded size smaller than computed (spec: the gate refuses only verification evidence)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); touch(dir, "lib/auth/x.rb"); commit(dir, "auth")
File.write("#{dir}/changes/a/08-attack/evidence/manifest.yml", "size: touched_doors_plus_smoke\ncommit_sha: #{sha}\n")
pick(sf(dir, "gate", "attack", "--change", "a"), /size|evidence current|stale|pass|fail/i)

case_ "ATTACK-007", "git failure reads as no change (THREAT-007)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
bogus = { "unknown 40-hex" => "f" * 40, "tree object hash" => tree(dir, sha), "short 7" => sha[0, 7], "HEAD" => "HEAD", "option-shaped" => "--output=/tmp/sf-attack-pwn", "range" => "#{sha}..HEAD", "empty" => "", "int" => 12345678, "tag name" => "v1", "uppercase hex" => sha.upcase }
bogus.each do |name, val|
  d2 = setup; s2 = with_records(d2, "a" => ["lib/a/**"]); touch(d2, "lib/a/x.rb"); commit(d2, "change")
  h = "#{d2}/changes/a/06-verification/handoff.yml"; d = YAML.safe_load_file(h); d["commit_sha"] = val; File.write(h, YAML.dump(d)); commit(d2, "bogus sha")
  puts "-- commit_sha #{name}"; pick(sf(d2, "gate", "verify", "--change", "a"), /evidence current|commit_sha|STALE|fail/i)
end
puts "(option-shaped created /tmp/sf-attack-pwn: #{File.exist?('/tmp/sf-attack-pwn') ? 'CREATED' : 'absent'})"
puts "-- branch recorded in metadata does not exist"
d2 = setup; s2 = with_records(d2, "a" => ["lib/a/**"]); meta(d2, "a") { |m| m["git"]["branch"] = "change/ghost" }; commit(d2, "ghost branch"); touch(d2, "lib/a/x.rb"); commit(d2, "change"); pick(sf(d2, "gate", "verify", "--change", "a"), EV)
puts "-- recorded branch is another local branch whose tip lacks the change"
d2 = setup; s2 = with_records(d2, "a" => ["lib/a/**"]); sh(d2, "git", "branch", "elsewhere"); meta(d2, "a") { |m| m["git"]["branch"] = "elsewhere" }; commit(d2, "point at elsewhere"); touch(d2, "lib/a/x.rb"); commit(d2, "change on main")
pick(sf(d2, "gate", "verify", "--change", "a"), EV)
puts "-- branch names that look like options or ref expressions"
["--all", "HEAD@{1}", "main~1", "refs/heads/main"].each do |b|
  d3 = setup; s3 = with_records(d3, "a" => ["lib/a/**"]); meta(d3, "a") { |m| m["git"]["branch"] = b }; commit(d3, "odd branch"); touch(d3, "lib/a/x.rb"); commit(d3, "change"); puts "   branch #{b}"; pick(sf(d3, "gate", "verify", "--change", "a"), EV)
end
puts "-- shallow clone missing the evidence commit"
d2 = setup; s2 = with_records(d2, "a" => ["lib/a/**"]); touch(d2, "lib/a/x.rb"); commit(d2, "change"); touch(d2, "lib/a/y.rb"); commit(d2, "change2")
sc = Dir.mktmpdir("sf-shallow"); sh(sc, "git", "clone", "-q", "--depth", "1", "file://#{d2}", "#{sc}/c")
pick(sf("#{sc}/c", "gate", "verify", "--change", "a"), EV)
puts "-- not a git repository"
nd = Dir.mktmpdir("sf-nogit"); FileUtils.cp_r("#{REPO}/.ai", nd); File.write("#{nd}/AGENTS.md", "x\n"); sf(nd, "change", "size", "a", "--phase", "verify")

case_ "ATTACK-009", "injection through slugs, YAML declarations and the CLI (THREAT-009)"
dir = setup
["../x", "-x", "a b", "a\nb", "$(id)", "a;ls", "A" * 300].each { |s| puts "-- change size slug #{s.inspect[0, 40]}"; sf(dir, "change", "size", s, "--phase", "verify") }
sha = with_records(dir, "a" => ["lib/a/**"])
["--output=/tmp/sf-attack-pwn2", "HEAD; id", "nonexistent", "#{sha}..HEAD", "-p"].each { |v| puts "-- --since #{v.inspect}"; sf(dir, "change", "size", "a", "--phase", "verify", "--since", v) }
puts "(pwn2 file: #{File.exist?('/tmp/sf-attack-pwn2') ? 'CREATED' : 'absent'})"
["../x", "plan", "", "verify --since x"].each { |v| puts "-- --phase #{v.inspect}"; sf(dir, "change", "size", "a", "--phase", v) }
puts "-- metadata scope with YAML alias / ruby tag"
%w[alias tag].each do |kind|
  d2 = setup; with_records(d2, "a" => ["lib/a/**"])
  m = File.read("#{d2}/changes/a/metadata.yml").sub(/^scope:\n(?:- .*\n)+/, "")
  File.write("#{d2}/changes/a/metadata.yml", m + (kind == "alias" ? "x: &s [\"lib/a/**\"]\nscope: *s\n" : "scope: !ruby/object:OpenStruct {a: 1}\n"))
  commit(d2, kind); puts "-- metadata with #{kind}"; pick(sf(d2, "gate", "verify", "--change", "a"), /evidence|fail|rror|alias|tag/i); pick(sf(d2, "check"), /fail|rror|scope/i)
end

case_ "ATTACK-010", "resource exhaustion (THREAT-010; optional case)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"])
n = 3000; n.times { |i| touch(dir, "lib/a/d#{i % 50}/f#{i}.rb", "#{i}\n") }; commit(dir, "many files")
t0 = Time.now; sf(dir, "gate", "verify", "--change", "a").lines.grep(/evidence current/).each { |l| puts "    >> #{l.strip[0, 160]}" }; puts "   #{n} changed files: #{(Time.now - t0).round(2)}s"
puts "-- pathological globs"
touch(dir, "lib/a/#{('a' * 60 + '/') * 3}z.rb"); commit(dir, "long")
meta(dir, "a") { |m| m["scope"] = ["**/*a*a*a*a*a*a*a*a*b/**/*", "lib/**/**/**/**/*a*a*a*a*c"] }; commit(dir, "path glob")
t0 = Time.now; Timeout.timeout(60) { sf(dir, "gate", "verify", "--change", "a").lines.grep(/evidence current/).each { |l| puts "    >> #{l.strip[0, 160]}" } }; puts "   pathological globs: #{(Time.now - t0).round(2)}s"
puts "-- 300 sibling records"
d2 = setup; sh(d2, *BIN, "change", "new", "a"); meta(d2, "a") { |m| m["scope"] = ["lib/a/**"] }
300.times { |i| FileUtils.mkdir_p("#{d2}/changes/s#{i}"); File.write("#{d2}/changes/s#{i}/metadata.yml", YAML.dump("scope" => ["lib/s#{i}/**"], "git" => { "branch" => "x" })) }
commit(d2, "records"); sha = head(d2); complete(d2, "a", sha); commit(d2, "phases"); touch(d2, "lib/other/x.rb"); commit(d2, "other")
t0 = Time.now; pick(sf(d2, "gate", "verify", "--change", "a"), /evidence current/); puts "   300 siblings: #{(Time.now - t0).round(2)}s"

case_ "ATTACK-011", "structural pass read as proof (THREAT-011)"
dir = setup; sha = with_records(dir, "a" => ["lib/a/**"]); t = tree(dir, sha)
tests_yml(dir, "a", { "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => t, "command" => "false", "outcome" => "passed" }, "checks" => [] }); commit(dir, "fabricated pass")
out = sf(dir, "gate", "verify", "--change", "a"); pick(out, /full-suite|check size/)
puts "   wording says record not result: #{out.include?('a record, not a test result')}"
pick(sf(dir, "change", "status", "a"), /full|record|suite|scope/i)

case_ "ATTACK-012", "markup in scope text; browser view (THREAT-012)"
dir = setup; with_records(dir, "a" => ["lib/a/**"])
evil = "lib/<img src=x onerror=alert(1)>/**"
meta(dir, "a") { |m| m["scope"] = [evil, "lib/a/**"] }; commit(dir, "html scope")
pick(sf(dir, "check"), /scope|glob|fail/i)
require "net/http"; require "json"
rd, wr = IO.pipe
pid = spawn({ "NO_COLOR" => "1" }, *BIN, "ui", "--no-open", "--port", "0", chdir: dir, out: wr, err: wr); wr.close
line = nil
begin
  Timeout.timeout(15) { while (l = rd.gets); (line = l; break) if l =~ %r{http://127\.0\.0\.1:\d+/#token=}; end }
rescue Timeout::Error
end
if line
  line =~ %r{http://127\.0\.0\.1:(\d+)/#token=(\S+)}; port, token = $1, $2
  http = Net::HTTP.new("127.0.0.1", port.to_i)
  [["/api/change?slug=a", token], ["/api/change?slug=a", "wrong"], ["/api/changes", token]].each do |path, tk|
    r = http.get(path, "x-soft-foundry-token" => tk); puts "GET #{path} (token #{tk == token ? 'valid' : 'wrong'}) -> #{r.code} #{r['content-type']}"
    next unless r.code == "200"
    j = JSON.parse(r.body) rescue nil
    puts "   scope field: #{j['scope'].inspect}" if j.is_a?(Hash) && j["scope"]
    puts "   nosniff/CSP: #{r['x-content-type-options'].inspect} #{r['content-security-policy'].inspect}"
  end
else
  puts "   ui did not start: #{(rd.read_nonblock(2000) rescue '')}"
end
Process.kill("TERM", pid) rescue nil; Process.wait(pid) rescue nil
puts "   innerHTML/insertAdjacentHTML/document.write/outerHTML occurrences in app.js: #{File.read("#{REPO}/lib/soft_foundry/ui/assets/app.js").lines.grep(/innerHTML|insertAdjacentHTML|document\.write|outerHTML/).size}"
