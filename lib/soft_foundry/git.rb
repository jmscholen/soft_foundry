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

    # The committer identity configured for this repository, or nil.
    def user_name
      out, ok = run("config", "user.name")
      ok && !out.strip.empty? ? out.strip : nil
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

    # The remote's default branch (via origin/HEAD), falling back to a local
    # main/master when there is no remote (e.g. a fresh or offline repo).
    def default_branch
      out, ok = run("symbolic-ref", "-q", "--short", "refs/remotes/origin/HEAD")
      return out.strip.sub(%r{\Aorigin/}, "") if ok && !out.strip.empty?
      %w[main master].find { |b| ref?("refs/heads/#{b}") }
    end

    # True when `sha` is already reachable from `ref` - i.e. its work has
    # already been merged.
    def ancestor?(sha, ref)
      return false unless sha.to_s.match?(/\A[0-9a-f]{7,40}\z/) && ref.to_s != ""
      _, ok = run("merge-base", "--is-ancestor", sha, ref)
      ok
    end

    # True when `path` exists in the tree of commit `sha`.
    def file_at?(sha, path)
      _, ok = run("cat-file", "-e", "#{sha}:#{path}")
      ok
    end

    # Paths changed in commits after `sha`, plus uncommitted and untracked paths.
    def changed_since(sha)
      committed, ok = run("diff", "--name-only", sha, "HEAD")
      committed = ok ? committed.lines(chomp: true) : []
      (committed + dirty_paths).uniq.sort
    end

    # Paths changed in commits between `sha` and `tip` (a commit or ref);
    # committed changes only, since another branch's worktree is not ours.
    def changed_between(sha, tip)
      out, ok = run("diff", "--name-only", sha, tip)
      ok ? out.lines(chomp: true).uniq.sort : []
    end

    # The commit a branch points at: local first, then origin's copy, so a
    # CI checkout that fetched every branch still finds it. Nil if neither.
    def branch_tip(name)
      return nil if name.to_s.strip.empty? || name.to_s == "HEAD"
      ["refs/heads/#{name}", "refs/remotes/origin/#{name}"].each do |ref|
        next unless ref?(ref)
        out, ok = run("rev-parse", ref)
        return out.strip if ok
      end
      nil
    end

    # Modified, staged, untracked, and ignored paths. Ignored directories are
    # reported with a trailing slash and cover everything beneath them.
    def dirty_paths
      out, ok = run("status", "--porcelain", "--untracked-files=all", "--ignored=matching")
      return [] unless ok
      out.lines(chomp: true).map { |line| line[3..].to_s.split(" -> ").last }
    end

    private

    def ref?(name)
      _, ok = run("show-ref", "--verify", "--quiet", name)
      ok
    end

    # GIT_DIR and GIT_WORK_TREE are cleared so the target directory alone
    # decides which repository is inspected.
    def run(*args)
      out, _err, status = Open3.capture3({ "GIT_DIR" => nil, "GIT_WORK_TREE" => nil }, "git", "-C", @root, *args)
      [out, status.success?]
    end
  end
end
