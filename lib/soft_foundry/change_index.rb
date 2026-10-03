# frozen_string_literal: true

require_relative "change_record"

module SoftFoundry
  # The change records of one repository: which exist, how to load one, and
  # whether one has merged without being closed. Shared by every command
  # that walks `changes/`.
  class ChangeIndex
    def initialize(root, plane:, git:)
      @root = File.expand_path(root)
      @plane = plane
      @git = git
    end

    # Slugs may contain "/" (a record per team or area), so every
    # metadata.yml under changes/ names one.
    def slugs
      base = File.join(@root, "changes")
      return [] unless File.directory?(base)
      Dir.glob("**/metadata.yml", base: base).map { |p| File.dirname(p) }.sort
    end

    def record(slug)
      record = ChangeRecord.new(@root, slug, control_plane: @plane)
      raise "no change record at changes/#{slug}" unless record.exists?
      record
    end

    def default_branch
      return @default_branch if defined?(@default_branch)
      @default_branch = @git.repository? ? @git.default_branch : nil
    end

    # The change's finished work is on the default branch but its record
    # was never closed. `ci` fails on it; `change close` settles it.
    def merged_unclosed?(record)
      return false if record.metadata["status"] == "closed"
      sha = record.finished_commit_sha
      !!(default_branch && sha && @git.ancestor?(sha, default_branch))
    end
  end
end
