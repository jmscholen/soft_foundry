# frozen_string_literal: true

require "open3"

module SoftFoundry
  # Thin wrapper over the git CLI for the few facts the harness needs.
  class Git
    def initialize(root)
      @root = File.expand_path(root)
    end

    def repository?
      run("rev-parse", "--is-inside-work-tree").first.strip == "true"
    rescue Errno::ENOENT
      false
    end

    def head_sha
      out, ok = run("rev-parse", "HEAD")
      ok ? out.strip : nil
    end

    def branch
      out, ok = run("rev-parse", "--abbrev-ref", "HEAD")
      ok ? out.strip : nil
    end

    def toplevel
      out, ok = run("rev-parse", "--show-toplevel")
      ok ? out.strip : nil
    rescue Errno::ENOENT
      nil
    end

    def ignored?(path)
      _, ok = run("check-ignore", "-q", path)
      ok
    end

    def commit?(sha)
      _, ok = run("cat-file", "-e", "#{sha}^{commit}")
      ok
    end

    # Paths changed in commits after `sha`, plus uncommitted and untracked paths.
    def changed_since(sha)
      committed, ok = run("diff", "--name-only", sha, "HEAD")
      committed = ok ? committed.lines(chomp: true) : []
      (committed + dirty_paths).uniq.sort
    end

    # Modified, staged, untracked, and ignored paths. Ignored directories are
    # reported with a trailing slash and cover everything beneath them.
    def dirty_paths
      out, ok = run("status", "--porcelain", "--untracked-files=all", "--ignored=matching")
      return [] unless ok
      out.lines(chomp: true).map { |line| line[3..].to_s.split(" -> ").last }
    end

    private

    # GIT_DIR and GIT_WORK_TREE are cleared so the target directory alone
    # decides which repository is inspected.
    def run(*args)
      out, _err, status = Open3.capture3({ "GIT_DIR" => nil, "GIT_WORK_TREE" => nil }, "git", "-C", @root, *args)
      [out, status.success?]
    end
  end
end
