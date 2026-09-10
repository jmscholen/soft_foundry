# frozen_string_literal: true

require "fileutils"
require_relative "errors"
require_relative "git"
require_relative "manifest"
require_relative "agent_files"
require_relative "installer/source"
require_relative "safe_write"
require_relative "version"

module SoftFoundry
  # Installs the control plane into a target repository. `plan` is pure and
  # computes one action per managed file; `apply` writes the plan under a lock
  # and records the manifest last.
  class Installer
    STATUSES = %w[created updated skipped conflict forced].freeze
    WRITING = %w[created updated forced].freeze
    LOCK = ".soft-foundry/init.lock"
    IGNORE_LINE = ".soft-foundry/"

    Action = Data.define(:path, :status, :reason, :bytes, :kind, :adopt) do
      def writes? = WRITING.include?(status)
    end

    Plan = Data.define(:actions, :warnings, :manifest, :clean, :extra_files) do
      def conflicts = actions.count { |a| a.status == "conflict" }
      def counts = STATUSES.to_h { |s| [s, actions.count { |a| a.status == s }] }
    end

    attr_reader :root, :source

    def initialize(root, source:, git: nil, force: false, allow_non_git: false, version: SoftFoundry::VERSION, writer: nil)
      @root = File.expand_path(root)
      @source = source
      @git = git || Git.new(@root)
      @force = force
      @allow_non_git = allow_non_git
      @version = version
      @writer = writer || method(:atomic_write)
    end

    def plan
      raise TargetError, "--force cannot be combined with --allow-non-git: overwrites would be unrecoverable" if @force && @allow_non_git

      # Guard every managed path before anything reads the target, so a FIFO or
      # symlink cannot hang or redirect the git and manifest reads below.
      SafeWrite.refuse_non_regular!(File.join(root, File.dirname(LOCK)), directory: true)
      ([".gitignore", "AGENTS.md", "CLAUDE.md", Manifest::PATH, LOCK] + source.paths).each { |rel| guard_path!(rel) }
      previous = Manifest.load(root)
      # Uncommitted edits are protected whenever a repository exists, even
      # under --allow-non-git; git-ignored files count as uncommitted.
      dirty = @git.repository? ? @git.dirty_paths : []
      actions = adapter_actions + source.entries.map { |entry| entry_action(entry, previous, dirty) }

      packaged = source.paths.select { |p| p.start_with?(".ai/") }
      warnings = (previous.files.keys - packaged).map { |p| "manifest entry ignored, not in the packaged set: #{p}" }

      manifest = Manifest.new(soft_foundry_version: @version)
      actions.each do |a|
        next unless a.kind == :ai
        if a.adopt
          manifest.add(a.path, a.bytes)
        elsif previous.include?(a.path)
          manifest.files[a.path] = previous.files[a.path]
        end
      end

      extra_files = Dir.glob(".ai/**/*", File::FNM_DOTMATCH, base: root)
                       .select { |rel| File.file?(File.join(root, rel)) && !File.symlink?(File.join(root, rel)) } - packaged - [".ai/repository.yml", Manifest::PATH]
      # A clean install touched nothing pre-existing: everything under .ai/
      # was created by this run or is byte-identical, and nothing else lives
      # there. Only then can a failing post-install check blame Soft Foundry.
      clean = actions.none? { |a| %w[conflict updated forced].include?(a.status) } &&
              actions.any? { |a| a.path == ".ai/repository.yml" && a.status == "created" } &&
              extra_files.empty?
      Plan.new(actions:, warnings:, manifest:, clean:, extra_files:)
    end

    # Writes every writing action, then the manifest. Returns written paths.
    def apply(plan)
      with_lock do
        written = write_actions(plan.actions)
        manifest_path = File.join(root, Manifest::PATH)
        bytes = plan.manifest.to_yaml
        unless File.file?(manifest_path) && File.binread(manifest_path) == bytes
          write(manifest_path, bytes, written)
          written << Manifest::PATH
        end
        written
      end
    end

    # .gitignore plus both pointer files; used by `onboard` without a manifest.
    def adapter_actions
      agents = AgentFiles.new(root, agents_interior: source.agents_interior)
      [gitignore_action, pointer(agents.plan_agents), pointer(agents.plan_claude)]
    end

    def write_actions(actions)
      written = []
      actions.select(&:writes?).each do |a|
        write(File.join(root, a.path), a.bytes, written)
        written << a.path
      end
      written
    end

    private

    def pointer(p) = Action.new(path: p.path, status: p.status, reason: p.reason, bytes: p.bytes, kind: :pointer, adopt: false)

    def gitignore_action
      guard_path!(".gitignore")
      path = File.join(root, ".gitignore")
      return Action.new(path: ".gitignore", status: "created", reason: "", bytes: "#{IGNORE_LINE}\n", kind: :ignore, adopt: false) unless File.exist?(path)

      body = File.binread(path)
      present = body.lines.map(&:strip).include?(IGNORE_LINE)
      effective = @allow_non_git ? present : @git.ignored?(IGNORE_LINE)
      if effective
        Action.new(path: ".gitignore", status: "skipped", reason: "#{IGNORE_LINE} is ignored", bytes: body, kind: :ignore, adopt: false)
      elsif present
        Action.new(path: ".gitignore", status: "conflict", reason: "#{IGNORE_LINE} line present but not effective", bytes: body, kind: :ignore, adopt: false)
      else
        separator = body.empty? || body.end_with?("\n") ? "" : "\n"
        Action.new(path: ".gitignore", status: "updated", reason: "appended #{IGNORE_LINE}", bytes: body + separator + "#{IGNORE_LINE}\n", kind: :ignore, adopt: false)
      end
    end

    def entry_action(entry, previous, dirty)
      guard_path!(entry.path)
      dest = File.join(root, entry.path)
      exists = File.exist?(dest)
      kind = if entry.path == ".ai/repository.yml" then :state
             elsif entry.path.start_with?(".ai/") then :ai
             else :scaffold
             end

      case kind
      when :state
        exists ? act(entry, "skipped", "repository state is owned by this repository", :state, false) : act(entry, "created", "", :state, false)
      when :scaffold
        if exists
          act(entry, "skipped", "user-owned scaffold", :scaffold, false)
        elsif entry.path == "docs/user/README.md" && File.exist?(File.join(root, "docs")) && !File.directory?(File.join(root, "docs", "user"))
          act(entry, "skipped", "docs/ exists without docs/user/", :scaffold, false)
        else
          act(entry, "created", "", :scaffold, false)
        end
      when :ai
        return act(entry, "created", "", :ai, true) unless exists
        existing = File.binread(dest)
        return act(entry, "skipped", "identical", :ai, true) if existing == entry.bytes
        return act(entry, "conflict", "uncommitted modifications", :ai, false) if dirty?(entry.path, dirty)
        return act(entry, "updated", "owned by manifest", :ai, true) if previous.owned?(entry.path, existing)
        reason = previous.include?(entry.path) ? "differs from manifest hash" : "not in manifest"
        @force ? act(entry, "forced", reason, :ai, true) : act(entry, "conflict", reason, :ai, false)
      end
    end

    def act(entry, status, reason, kind, adopt)
      Action.new(path: entry.path, status: status, reason: reason, bytes: entry.bytes, kind: kind, adopt: adopt)
    end

    def dirty?(path, dirty)
      dirty.any? { |d| d == path || (d.end_with?("/") && path.start_with?(d)) }
    end

    # No symlink or non-regular file may sit at or above a managed destination,
    # and no temporary sibling may be waiting to be written through.
    def guard_path!(rel)
      sibling = File.join(root, rel + SafeWrite::TMP_SUFFIX)
      if File.symlink?(sibling) || File.exist?(sibling)
        raise TargetError, "#{rel}#{SafeWrite::TMP_SUFFIX} exists (planted or leftover temporary file); remove it and rerun"
      end
      parts = rel.split("/")
      parts.each_index do |i|
        sub = parts[0..i].join("/")
        abs = File.join(root, sub)
        raise TargetError, "#{sub} is a symlink; init does not write through symlinks" if File.symlink?(abs)
        next unless File.exist?(abs)
        last = i == parts.size - 1
        raise TargetError, "#{sub} is not a directory" if !last && !File.directory?(abs)
        raise TargetError, "#{sub} is not a regular file" if last && !File.file?(abs)
      end
    end

    def with_lock
      SafeWrite.ensure_directory!(File.join(root, File.dirname(LOCK)))
      SafeWrite.refuse_symlink!(File.join(root, LOCK))
      File.open(File.join(root, LOCK), File::RDWR | File::CREAT | File::NOFOLLOW, 0o644) do |lock|
        raise TargetError, "another soft-foundry init is running (#{LOCK} is locked)" unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        yield
      end
    end

    def write(path, bytes, written)
      @writer.call(path, bytes)
    rescue TargetError => e
      raise TargetError, "#{e.message}; files already written: #{written.empty? ? 'none' : written.join(', ')}; manifest #{written.include?(Manifest::PATH) ? 'written' : 'not written'}"
    rescue SystemCallError, IOError => e
      rel = path.delete_prefix("#{root}/")
      raise TargetError, "write failed at #{rel} (#{e.message}); files already written: #{written.empty? ? 'none' : written.join(', ')}; manifest #{written.include?(Manifest::PATH) ? 'written' : 'not written'}"
    end

    def atomic_write(path, bytes)
      FileUtils.mkdir_p(File.dirname(path))
      SafeWrite.write(path, bytes)
    end
  end
end
