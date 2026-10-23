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

