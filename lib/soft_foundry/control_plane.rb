# frozen_string_literal: true

require "yaml"

module SoftFoundry
  # Reads the `.ai/` directory: workflow, skills, path groups, profiles.
  class ControlPlane
    Phase = Data.define(:id, :skill, :output, :optional, :after)
    Skill = Data.define(:name, :dir, :definition, :permissions, :requirements, :completion) do
      def template_dir = File.join(dir, "template")
      def profile = definition["model"]
      def commit_bound? = definition["evidence"] == "commit_bound"
      def required_files = Array(completion["required_files"])
      def blocking_conditions = Array(completion["blocking"])
    end

    REQUIRED_GROUPS = %w[APP TESTS INFRA DOCS CONTROL_PLANE HARNESS_EVALS].freeze
    SKILL_FILES = %w[skill.yml SKILL.md permissions.yml requirements.yml completion.yml].freeze
    VARIABLE = /\$\{([A-Z_]+)\}/

    attr_reader :root

    def initialize(root)
      @root = File.expand_path(root)
    end

    def dir = File.join(root, ".ai")
    def present? = File.exist?(File.join(dir, "workflow.yml"))

    def workflow
      @workflow ||= load_yaml(File.join(dir, "workflow.yml"))
    end

    def phases
      @phases ||= Array(workflow["lifecycle"]).map do |entry|
        Phase.new(id: entry["id"], skill: entry["skill"], output: entry["output"], optional: entry["optional"] == true, after: entry["after"])
      end
    end

    def phase(key)
      phases.find { |p| p.id == key || p.output == key }
    end

    def predecessor(phase)
      return phase(phase.after) if phase.after
      previous_in_lifecycle(phase)
    end

    def previous_in_lifecycle(phase)
      index = phases.index(phase)
      index&.positive? ? phases[index - 1] : nil
    end

    # The phase whose completion gates `phase`: its predecessor, stepping back
    # in lifecycle order over any phase that is both pending and skippable.
    # A phase is skippable when it is globally `optional:` or when `skip`
    # says so (typically: this change's own recorded skipped_phases, each
    # requiring a non-empty rationale). `status_of` maps a phase to its
    # recorded handoff status.
    def effective_predecessor(phase, skip: ->(_p) { false }, &status_of)
      prev = predecessor(phase)
      prev = previous_in_lifecycle(prev) while prev && (prev.optional || skip.call(prev)) && status_of.call(prev) == "pending"
      prev
    end

    def successor(phase)
      index = phases.index(phase)
      index ? phases[index + 1] : nil
    end

    def transitions = workflow.fetch("transitions", {})
    def rules = workflow.fetch("rules", {})
    def judgments = Array(workflow["judgments"])

    def skill(name)
      (@skills ||= {})[name] ||= begin
        skill_dir = File.join(dir, "skills", name)
        raise ArgumentError, "unknown skill '#{name}'" unless File.directory?(skill_dir)
        Skill.new(
          name: name,
          dir: skill_dir,
          definition: load_yaml(File.join(skill_dir, "skill.yml")),
          permissions: load_yaml(File.join(skill_dir, "permissions.yml")),
          requirements: load_yaml(File.join(skill_dir, "requirements.yml")),
          completion: load_yaml(File.join(skill_dir, "completion.yml"))
        )
      end
    end

    def skill_names
      Dir.children(File.join(dir, "skills")).select { |n| File.directory?(File.join(dir, "skills", n)) }.sort
    end

    def profile_names
      Dir[File.join(dir, "profiles", "*.yml")].map { |f| load_yaml(f)["name"] }.compact
    end

    def maturity_policy
      @maturity_policy ||= load_yaml(File.join(dir, "maturity.yml"))
    end

    # Scores a capabilities hash (capability => {"status" => ...}) against
    # .ai/maturity.yml's levels and scoring rule. Shared by every assessment
    # mode (deterministic scan, agentic deep-assess, or hand-written) so the
    # rule lives in exactly one place.
    def score_maturity(capabilities)
      policy = maturity_policy
      satisfied = policy.dig("scoring", "satisfied_statuses") || []
      levels = policy.fetch("levels", {}).sort_by { |num, _| num.to_i }
      current = levels.first
      gaps = []
      levels.each do |num, level|
        required = Array(level["requires"])
        unmet = required.reject { |cap| satisfied.include?(capabilities.dig(cap, "status")) }
        if unmet.empty?
          current = [num, level]
        else
          gaps = unmet.map { |cap| { "level" => num.to_i, "capability" => cap, "status" => capabilities.dig(cap, "status") || "UNKNOWN" } }
          break
        end
      end
      { "current_level" => current[0].to_i, "current_id" => current[1]["id"], "gaps" => gaps }
    end

    def protected_patterns
      policy = File.join(dir, "policies", "skill-permissions.yml")
      File.exist?(policy) ? Array(load_yaml(policy)["protected"]) : []
    end

    # Groups that repository.yml may never override: they protect policy and
    # harness material regardless of the repository's layout.
    PROTECTED_GROUPS = %w[CONTROL_PLANE HARNESS_EVALS].freeze

    def default_path_groups
      @default_path_groups ||= load_yaml(File.join(dir, "paths.yml")).fetch("groups", {}).transform_values { |v| Array(v) }
    end

    def override_path_groups
      @override_path_groups ||= begin
        repo = File.join(dir, "repository.yml")
        raw = File.exist?(repo) ? load_yaml(repo).fetch("paths", nil) || {} : {}
        raw.is_a?(Hash) ? raw.transform_values { |v| Array(v) } : {}
      end
    end

    # Path groups from paths.yml, overridden group by group from repository.yml,
    # except protected groups, which keep their defaults.
    def path_groups
      @path_groups ||= default_path_groups.merge(override_path_groups.reject { |g, _| PROTECTED_GROUPS.include?(g) })
    end

    # Files in this repository matched by a group's patterns.
    def files_matching(globs)
      globs.flat_map { |g| Dir.glob(g.end_with?("/**") ? "#{g}/*" : g, File::FNM_DOTMATCH, base: root) }
           .select { |rel| File.file?(File.join(root, rel)) }.uniq
    end

    def code_globs
      %w[APP TESTS INFRA].flat_map { |g| path_groups.fetch(g, []) }
    end

    # Expands one permission pattern into concrete globs.
    def expand(pattern, change: "CHANGE")
      if (m = pattern.match(/\A\$\{([A-Z_]+)\}\z/))
        group = m[1]
        return [pattern.sub(VARIABLE, change)] if group == "CHANGE"
        path_groups.fetch(group) { raise ArgumentError, "unknown path group '#{group}'" }
      else
        [pattern.gsub("${CHANGE}", change)]
      end
    end

    def variables_in(pattern)
      pattern.scan(VARIABLE).flatten
    end

    def self.match?(path, glob)
      return true if glob == "**"
      if glob.end_with?("/**")
        prefix = glob.delete_suffix("/**")
        return path == prefix || path.start_with?("#{prefix}/")
      end
      File.fnmatch(glob, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB)
    end

    def self.match_any?(path, globs)
      globs.any? { |g| match?(path, g) }
    end

    private

    def load_yaml(path)
      YAML.safe_load_file(path, aliases: true) || {}
    end
  end
end
