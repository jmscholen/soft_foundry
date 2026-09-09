# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require_relative "../lib/soft_foundry"

module FoundryFixture
  REPO_ROOT = File.expand_path("..", __dir__)

  # A throwaway git repository carrying a copy of this repo's .ai/ control plane.
  def with_fixture_repo
    Dir.mktmpdir("soft-foundry") do |dir|
      FileUtils.cp_r(File.join(REPO_ROOT, ".ai"), dir)
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "lib", "app.rb"), "puts 1\n")
      File.write(File.join(dir, "AGENTS.md"), "# agents\n")
      sh(dir, "git", "init", "-q", "-b", "main")
      sh(dir, "git", "config", "user.email", "test@example.com")
      sh(dir, "git", "config", "user.name", "Test")
      sh(dir, "git", "add", ".")
      sh(dir, "git", "commit", "-q", "-m", "initial")
      yield dir
    end
  end

  def sh(dir, *cmd)
    out, err, status = Open3.capture3(*cmd, chdir: dir)
    raise "#{cmd.join(' ')} failed: #{err}" unless status.success?
    out
  end

  def head(dir) = sh(dir, "git", "rev-parse", "HEAD").strip

  def cli(dir, *args)
    out = StringIO.new
    err = StringIO.new
    code = SoftFoundry::CLI.new(args, out: out, err: err, root: dir).run
    [code, out.string + err.string]
  end

  def complete_phase!(record, phase_id, sha:, fill: true)
    phase = record.control_plane.phase(phase_id)
    dir = record.phase_dir(phase)
    if fill
      Dir.glob("**/*", base: dir).each do |rel|
        path = File.join(dir, rel)
        File.write(path, File.read(path).gsub(/\bTBD\b/, "done")) if File.file?(path)
      end
    end
    handoff = YAML.safe_load_file(File.join(dir, "handoff.yml"))
    handoff.merge!("status" => "complete", "commit_sha" => sha, "completed_at" => "2026-09-09T00:00:00Z")
    File.write(File.join(dir, "handoff.yml"), YAML.dump(handoff))
  end
end
