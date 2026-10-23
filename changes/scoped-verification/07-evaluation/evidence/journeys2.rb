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

require 'json'; require 'timeout'

def tests_yml(dir, slug, data) = File.write("#{dir}/changes/#{slug}/06-verification/tests.yml", YAML.dump(data))
def tree(dir, sha) = sh(dir, "git", "rev-parse", "#{sha}^{tree}")[0].strip
def pick(out, pat) = puts(out.lines.grep(pat).map { |l| "    >> #{l.strip}" })

puts "##### J-FULLSUITE: record, cite, mismatch, dirty tree"
dir = setup
%w[a b].each { |s| sh(dir, *BIN, "change", "new", s) }
meta(dir, "a") { |m| m["scope"] = ["lib/a/**"] }; meta(dir, "b") { |m| m["scope"] = ["lib/b/**"] }
commit(dir, "records"); sha = head(dir); %w[a b].each { |s| complete(dir, s, sha) }; commit(dir, "phases")
t = tree(dir, sha)
FS = "full-suite run recorded"
puts "-- a records a run with the evidence commit's tree"
tests_yml(dir, "a", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => t, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
commit(dir, "a tests"); pick(sf(dir, "gate", "verify", "--change", "a"), /#{FS}|check size/)
puts "-- a records the wrong tree"
tests_yml(dir, "a", "commit_sha" => sha, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => "0" * 40, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
commit(dir, "a wrong tree"); pick(sf(dir, "gate", "verify", "--change", "a"), /#{FS}/)
puts "-- a records outcome failed"
tests_yml(dir, "a", "commit_sha" => sha, "full_suite" => { "tree" => t, "command" => "rake test", "outcome" => "failed" }, "checks" => [])
commit(dir, "a failed"); pick(sf(dir, "gate", "verify", "--change", "a"), /#{FS}/)
puts "-- a records a good run again; b cites a"
tests_yml(dir, "a", "commit_sha" => sha, "full_suite" => { "tree" => t, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
tests_yml(dir, "b", "commit_sha" => sha, "full_suite" => { "cite" => "a" }, "checks" => [])
commit(dir, "b cites a"); pick(sf(dir, "gate", "verify", "--change", "b"), /#{FS}/)
puts "-- b cites a record that does not exist"
tests_yml(dir, "b", "commit_sha" => sha, "full_suite" => { "cite" => "nope" }, "checks" => []); commit(dir, "b cites nope"); pick(sf(dir, "gate", "verify", "--change", "b"), /#{FS}/)
puts "-- b cites a with a dirty code path"
tests_yml(dir, "b", "commit_sha" => sha, "full_suite" => { "cite" => "a" }, "checks" => []); commit(dir, "b cites a again")
touch(dir, "lib/a/dirty.rb"); pick(sf(dir, "gate", "verify", "--change", "b"), /#{FS}/); File.delete("#{dir}/lib/a/dirty.rb")
puts "-- b cites a whose evidence tree differs (a's run is on another tree)"
tests_yml(dir, "a", "commit_sha" => sha, "full_suite" => { "tree" => "1" * 40, "command" => "rake test", "outcome" => "passed" }, "checks" => []); commit(dir, "a other tree")
pick(sf(dir, "gate", "verify", "--change", "b"), /#{FS}/)
puts "-- b cites itself / path-shaped slug"
tests_yml(dir, "b", "commit_sha" => sha, "full_suite" => { "cite" => "../a" }, "checks" => []); commit(dir, "b path cite"); pick(sf(dir, "gate", "verify", "--change", "b"), /#{FS}/)

puts "\n##### J-CONSUMER: a code change in b's scope leaves a current; phase run refuses, status shows current"
d2 = setup
%w[a b].each { |s| sh(d2, *BIN, "change", "new", s) }
meta(d2, "a") { |m| m["scope"] = ["lib/a/**"] }; meta(d2, "b") { |m| m["scope"] = ["lib/b/**"] }
commit(d2, "records"); s2 = head(d2); %w[a b].each { |s| complete(d2, s, s2) }; commit(d2, "phases")
t2 = tree(d2, s2)
tests_yml(d2, "a", "commit_sha" => s2, "size" => "targeted_plus_full_before_merge", "full_suite" => { "tree" => t2, "command" => "rake test", "outcome" => "passed" }, "checks" => [])
commit(d2, "a verification recorded")
puts "-- before b's code lands: a's verify gate"; pick(sf(d2, "gate", "verify", "--change", "a"), /evidence current|check size|full-suite/)
touch(d2, "lib/b/new.rb"); commit(d2, "b code")
puts "-- after b's code lands (outside a's scope, claimed by b): a's verify gate"; pick(sf(d2, "gate", "verify", "--change", "a"), /evidence current|check size|full-suite/)
sf(d2, "phase", "run", "verify", "--change", "a", "--dry-run")
sf(d2, "phase", "run", "verify", "--change", "b", "--dry-run")
pick(sf(d2, "change", "status", "a"), /stale|current|verification|scope|06-verification/)
puts "\n--- browser view data: scope and staleness as text"
r, w = IO.pipe
pid = spawn({ "NO_COLOR" => "1" }, *BIN, "ui", "--port", "0", chdir: d2, out: w, err: w); w.close
url = nil; Timeout.timeout(20) { url = r.gets[/http\S+/] } rescue nil
puts "ui url (token elided): #{url.to_s.sub(/token=[^&\s]+/, 'token=...')}"
if url
  base = url.sub(%r{/#.*}, "")
  require "net/http"
  %w[a b].each do |slug|
    uri = URI("#{base}/api/change?slug=#{slug}")
    req = Net::HTTP::Get.new(uri); req["x-soft-foundry-token"] = url[/token=(\S+)/, 1]
    res = Net::HTTP.start(uri.host, uri.port) { |h| h.request(req) }
    j = (JSON.parse(res.body) rescue {})
    puts "  GET /api/change?slug=#{slug} -> #{res.code}; scope=#{j['scope'].inspect}; stale=#{j['stale'].inspect}; gate states=#{(j['gates'] || []).map { |g| "#{g['id'] || g['phase']}=#{g['state']}" }.join(' ')}"
  end
  res = Net::HTTP.get_response(URI("#{base}/api/change?slug=a")); puts "  without token -> #{res.code}"
  js = Net::HTTP.get(URI("#{base}/app.js")); puts "  app.js has 'Scope: ' text label: #{js.include?('"Scope: "')}; word 'Stale' for stale state: #{js.include?('stale: "Stale"')}"
end
Process.kill("TERM", pid) rescue nil; Process.wait(pid) rescue nil

puts "\n##### J-BRANCH: record on a branch that exists but is not checked out"
d5 = setup; sh(d5, *BIN, "change", "new", "a"); meta(d5, "a") { |m| m["scope"] = ["lib/a/**"] }
commit(d5, "rec"); complete(d5, "a", head(d5)); commit(d5, "ph")
meta(d5, "a") { |m| m["git"]["branch"] = "change/a" }; commit(d5, "record the branch")
sh(d5, "git", "checkout", "-q", "-b", "change/a"); touch(d5, "lib/a/y.rb"); commit(d5, "a work on branch")
sh(d5, "git", "checkout", "-q", "main")
puts "(main is checked out; branch change/a holds lib/a/y.rb)"
sf(d5, "change", "size", "a", "--phase", "verify")
FileUtils.rm_rf([dir, d2, d5])
