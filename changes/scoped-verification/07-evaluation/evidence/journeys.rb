# Evaluation driver for scoped-verification. Builds throwaway git repositories
# carrying a copy of this checkout's .ai/ and drives the real CLI
# (ruby -Ilib exe/soft-foundry) through the journeys in journeys.yml.
# Usage: ruby journeys.rb <checkout> > transcript.txt
require "tmpdir"; require "fileutils"; require "open3"; require "yaml"
REPO = File.expand_path(ARGV.fetch(0))
BIN = ["ruby", "-I#{REPO}/lib", "#{REPO}/exe/soft-foundry"]
def sh(dir, *c) = Open3.capture2e(*c, chdir: dir)
def sf(dir, *a)
  out, st = Open3.capture2e({ "NO_COLOR" => "1" }, *BIN, *a, chdir: dir)
  puts "$ soft-foundry #{a.join(' ')}"
  puts out.lines.map { |l| "  #{l}" }.join
  puts "  [exit #{st.exitstatus}]"
  out
end
def commit(dir, m) = (sh(dir, "git", "add", "-A"); sh(dir, "git", "commit", "-q", "-m", m))
def head(dir) = sh(dir, "git", "rev-parse", "HEAD")[0].strip
def touch(dir, rel, body = "puts #{rand(10**6)}\n") = (FileUtils.mkdir_p(File.dirname(File.join(dir, rel))); File.write(File.join(dir, rel), body))
def complete(dir, slug, sha)
  Dir.glob("#{dir}/changes/#{slug}/*/").each do |pd|
    Dir.glob("**/*", base: pd).each { |r| p = File.join(pd, r); File.write(p, File.read(p).gsub(/\bTBD\b/, "done")) if File.file?(p) }
    next unless (1..7).cover?(File.basename(pd)[0, 2].to_i)
    h = File.join(pd, "handoff.yml"); d = YAML.safe_load_file(h)
    d.merge!("status" => "complete", "commit_sha" => sha, "completed_at" => "2026-09-09T00:00:00Z"); File.write(h, YAML.dump(d))
  end
end
def meta(dir, slug) = (p = File.join(dir, "changes", slug, "metadata.yml"); d = YAML.safe_load_file(p, permitted_classes: [Time, Date]); yield d; File.write(p, YAML.dump(d)))
def setup
  dir = Dir.mktmpdir("sf-eval"); FileUtils.cp_r("#{REPO}/.ai", dir)
  File.write("#{dir}/AGENTS.md", "# agents\n")
  %w[a b base other auth].each { |d| touch(dir, "lib/#{d}/f.rb", "puts '#{d}'\n") }
  File.open("#{dir}/.ai/repository.yml", "a") { |f| f.puts "shared_core:\n  - lib/base/**\naccess_control:\n  - lib/auth/**" }
  sh(dir, "git", "init", "-q", "-b", "main"); sh(dir, "git", "config", "user.email", "e@x"); sh(dir, "git", "config", "user.name", "E"); commit(dir, "initial")
  dir
end
def scoped_record(dir, slug, scope)
  sf(dir, "change", "new", slug) if false
  meta(dir, slug) { |m| m["scope"] = scope } unless scope.nil?
end
def evidence_line(out) = puts(out.lines.grep(/evidence current|stale|scope|unclaimed|shared core|declaration/i).map { |l| "    >> #{l.strip}" })

puts "##### J-STALE: legacy (no scope), empty scope, A (lib/a/**), B (lib/b/**) with evidence at one commit"
dir = setup
%w[legacy empty a b].each { |s| sh(dir, *BIN, "change", "new", s) }
meta(dir, "empty") { |m| m["scope"] = [] }; meta(dir, "a") { |m| m["scope"] = ["lib/a/**"] }; meta(dir, "b") { |m| m["scope"] = ["lib/b/**"] }
commit(dir, "records"); sha = head(dir)
%w[legacy empty a b].each { |s| complete(dir, s, sha) }; commit(dir, "phases complete")
sf(dir, "check")
puts "\n--- sizes before any code change"
sf(dir, "change", "size", "a", "--phase", "verify")
puts "\n--- code change under lib/a after evidence"
touch(dir, "lib/a/new.rb"); commit(dir, "change a")
%w[legacy empty a b].each { |s| puts "-- #{s}"; evidence_line(sf(dir, "gate", "verify", "--change", s)) }
puts "\n--- code change under lib/b: A must not be stale because of it"
touch(dir, "lib/b/new.rb"); commit(dir, "change b"); puts "-- a (a changed earlier; look for lib/b mention)"; sf(dir, "gate", "verify", "--change", "a")
puts "\n--- unclaimed lib/other"
touch(dir, "lib/other/new.rb"); commit(dir, "change other"); puts "-- b"; sf(dir, "gate", "verify", "--change", "b")
puts "\n--- shared core lib/base"
touch(dir, "lib/base/new.rb"); commit(dir, "change base"); puts "-- b"; sf(dir, "gate", "verify", "--change", "b")
puts "\n--- sizes with out-of-scope and shared-core paths"
sf(dir, "change", "size", "a", "--phase", "verify"); sf(dir, "change", "size", "a", "--phase", "evaluate")

puts "\n##### J-SIZE: only in-scope diff"
d2 = setup; sh(d2, *BIN, "change", "new", "a"); meta(d2, "a") { |m| m["scope"] = ["lib/a/**"] }; commit(d2, "rec"); complete(d2, "a", head(d2)); commit(d2, "ph")
touch(d2, "lib/a/x.rb"); commit(d2, "in scope")
%w[verify evaluate attack].each { |p| sf(d2, "change", "size", "a", "--phase", p) }
puts "\n--- diff touches access control"
touch(d2, "lib/auth/x.rb"); commit(d2, "auth"); sf(d2, "change", "size", "a", "--phase", "evaluate"); sf(d2, "change", "size", "a", "--phase", "attack")
puts "\n--- branch exists but is not checked out"
d5 = setup; sh(d5, *BIN, "change", "new", "a"); meta(d5, "a") { |m| m["scope"] = ["lib/a/**"] }; meta(d5, "a") { |m| m["git"] ||= {}; m["git"]["branch"] = "change/a" }
commit(d5, "rec"); sh(d5, "git", "checkout", "-q", "-b", "change/a"); complete(d5, "a", head(d5)); commit(d5, "ph"); touch(d5, "lib/a/y.rb"); commit(d5, "a work")
sh(d5, "git", "checkout", "-q", "main"); sf(d5, "change", "size", "a", "--phase", "verify")

puts "\n##### J-DECL: narrowing scope after evidence"
meta(d2, "a") { |m| m["scope"] = ["lib/a/sub/**"] }; commit(d2, "narrow"); evidence_line(sf(d2, "gate", "verify", "--change", "a"))

puts "\n##### J-MALFORMED declarations"
d3 = setup; sh(d3, *BIN, "change", "new", "a")
[[["/abs/**"], "absolute"], [["../x/**"], "dotdot"], [["lib/nomatch/**"], "matches no tracked file"], [[""], "empty glob"]].each do |s, l|
  meta(d3, "a") { |m| m["scope"] = s }; puts "-- #{l}"; sf(d3, "check")
end
meta(d3, "a") { |m| m.delete("scope") }
File.write("#{d3}/.ai/repository.yml", File.read("#{d3}/.ai/repository.yml").sub("shared_core:\n  - lib/base/**", "shared_core:\n  - notes/**")); touch(d3, "notes/x.md", "x\n"); commit(d3, "n")
puts "-- shared core outside code path groups"; sf(d3, "check")

puts "\n##### J-FAILCLOSED: evidence commit unknown to git"
d4 = setup; sh(d4, *BIN, "change", "new", "a"); meta(d4, "a") { |m| m["scope"] = ["lib/a/**"] }; commit(d4, "r"); complete(d4, "a", "f" * 40); commit(d4, "ph")
evidence_line(sf(d4, "gate", "verify", "--change", "a"))
FileUtils.rm_rf([dir, d2, d3, d4, d5])
