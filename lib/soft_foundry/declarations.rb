# frozen_string_literal: true

require_relative "control_plane"

module SoftFoundry
  # Validation of the path-glob declarations scoped verification reads: a
  # record's `scope`, and a repository's `shared_core` and `access_control`.
  # A misdeclared glob silently lets stale evidence pass, so the structure
  # check and the gate both refuse what this reports. Globs are only ever
  # matched as paths against repository-relative git paths.
  module Declarations
    MAX_LENGTH = 200
    MAX_GROUPS = 6 # `**` and `{` occurrences, which bound brace expansion

    # Messages naming each problem and the fix, empty when the declaration
    # is well formed. `tracked_files` are the repository's tracked paths.
    def self.problems(list, tracked_files:, code_globs:, kind:)
      return ["#{kind} must be a list of path globs"] unless list.is_a?(Array)
      list.flat_map do |glob|
        found = syntax_problems(glob, kind)
        next found unless found.empty?
        matched = tracked_files.select { |f| ControlPlane.match?(f, glob) }
        next ["#{kind} glob '#{glob}' matches no tracked file; declare a path that exists or remove it"] if matched.empty?
        if kind == :shared_core && matched.none? { |f| ControlPlane.match_any?(f, code_globs) }
          next ["#{kind} glob '#{glob}' matches nothing within the code path groups (#{code_globs.join(', ')}); a shared core outside them never stales evidence, so declare code paths"]
        end
        []
      end
    end

    # Problems that need no repository: the shape of one glob.
    def self.syntax_problems(glob, kind)
      return ["#{kind} entry #{glob.inspect} is not a string; write a path glob"] unless glob.is_a?(String)
      shown = glob.dump
      return ["#{kind} glob #{shown} is empty; declare a path glob or remove it"] if glob.strip.empty?
      return ["#{kind} glob #{shown} has a control character; use a plain path glob"] if glob.match?(/[[:cntrl:]]/)
      return ["#{kind} glob #{shown} is longer than #{MAX_LENGTH} characters; shorten it"] if glob.length > MAX_LENGTH
      return ["#{kind} glob #{shown} is absolute; use a path relative to the repository root"] if glob.start_with?("/")
      return ["#{kind} glob #{shown} starts with a dash; start it with a directory name"] if glob.start_with?("-")
      return ["#{kind} glob #{shown} has a parent-directory segment; use a path inside the repository"] if glob.split("/").include?("..")
      return ["#{kind} glob #{shown} has more than #{MAX_GROUPS} ** or {} groups; simplify it"] if glob.scan(/\*\*|\{/).size > MAX_GROUPS
      []
    end

    # Whether a record's own scope is well formed enough to claim paths: a
    # non-empty list of syntactically valid globs. Whether each glob matches
    # a tracked file is the structure check's job.
    def self.claimable?(list)
      list.is_a?(Array) && !list.empty? && list.all? { |g| syntax_problems(g, :scope).empty? }
    end
  end
end
