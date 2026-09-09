# frozen_string_literal: true

require "yaml"

module SoftFoundry
  # Reads the `.ai/` directory: workflow, skills, path groups, profiles.
  class ControlPlane
    Phase = Data.define(:id, :skill, :output)
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
      @phases ||= Array(workflow["lifecycle"]).map { |entry| Phase.new(id: entry["id"], skill: entry["skill"], output: entry["output"]) }
    end

    def phase(key)
      phases.find { |p| p.id == key || p.output == key }
    end

    def predecessor(phase)
      index = phases.index(phase)
      index&.positive? ? phases[index - 1] : nil
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

    def protected_patterns
      policy = File.join(dir, "policies", "skill-permissions.yml")
      File.exist?(policy) ? Array(load_yaml(policy)["protected"]) : []
    end

    # Path groups from paths.yml, overridden group by group from repository.yml.
    def path_groups
      @path_groups ||= begin
        base = load_yaml(File.join(dir, "paths.yml")).fetch("groups", {})
        repo = File.join(dir, "repository.yml")
        overrides = File.exist?(repo) ? load_yaml(repo).fetch("paths", nil) || {} : {}
        base.merge(overrides).transform_values { |v| Array(v) }
      end
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
