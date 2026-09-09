# frozen_string_literal: true

module SoftFoundry
  # Lints the `.ai/` control plane itself: every phase has a skill, every skill
  # has its contract files and templates, permissions reference known path
  # groups, and no skill can write protected policy.
  class Check
    Finding = Data.define(:level, :message) # :error | :warning

    def initialize(control_plane)
      @plane = control_plane
    end

    def run
      findings = []
      return [Finding.new(:error, ".ai/workflow.yml not found")] unless @plane.present?

      findings.concat(check_templates)
      findings.concat(check_path_groups)
      findings.concat(check_transitions)
      @plane.phases.each { |phase| findings.concat(check_phase(phase)) }
      findings
    end

    private

    def check_templates
      %w[templates/handoff.yml templates/change/metadata.yml].reject { |f| File.exist?(File.join(@plane.dir, f)) }
                                                              .map { |f| Finding.new(:error, ".ai/#{f} is missing") }
    end

    def check_path_groups
      missing = ControlPlane::REQUIRED_GROUPS - @plane.path_groups.keys
      missing.map { |g| Finding.new(:error, "paths.yml lacks required group #{g}") }
    rescue Errno::ENOENT
      [Finding.new(:error, ".ai/paths.yml is missing")]
    end

    def check_transitions
      ids = @plane.phases.map(&:id)
      @plane.transitions.flat_map do |from, edges|
        problems = []
        problems << Finding.new(:error, "transitions: '#{from}' is not a lifecycle phase") unless ids.include?(from)
        Hash(edges).each_value { |to| problems << Finding.new(:error, "transitions: '#{from}' targets unknown phase '#{to}'") unless ids.include?(to) }
        problems
      end
    end

    def check_phase(phase)
      skill_dir = File.join(@plane.dir, "skills", phase.skill)
      return [Finding.new(:error, "phase #{phase.id}: skill directory '#{phase.skill}' is missing")] unless File.directory?(skill_dir)

      missing = ControlPlane::SKILL_FILES.reject { |f| File.exist?(File.join(skill_dir, f)) }
      return missing.map { |f| Finding.new(:error, "skill #{phase.skill}: #{f} is missing") } unless missing.empty?

      skill = @plane.skill(phase.skill)
      findings = []
      findings << Finding.new(:error, "skill #{skill.name}: skill.yml name is '#{skill.definition['name']}'") unless skill.definition["name"] == skill.name
      findings << Finding.new(:error, "skill #{skill.name}: profile '#{skill.profile}' has no .ai/profiles definition") unless @plane.profile_names.include?(skill.profile)
      findings << Finding.new(:error, "skill #{skill.name}: completion.yml must require handoff.yml") unless skill.required_files.include?("handoff.yml")
      (skill.required_files - ["handoff.yml"]).each do |f|
        findings << Finding.new(:error, "skill #{skill.name}: required file '#{f}' has no template") unless File.exist?(File.join(skill.template_dir, f))
      end
      findings.concat(check_permissions(skill))
      findings
    end

    def check_permissions(skill)
      findings = []
      perms = skill.permissions
      %w[read write deny_read deny_write].each do |key|
        Array(perms[key]).each do |pattern|
          (@plane.variables_in(pattern) - ["CHANGE"]).each do |var|
            findings << Finding.new(:error, "skill #{skill.name}: #{key} references unknown path group ${#{var}}") unless @plane.path_groups.key?(var)
          end
        end
      end
      return findings unless findings.empty?

      writes = Array(perms["write"]).flat_map { |p| @plane.expand(p) }
      @plane.protected_patterns.each do |protected|
        writes.each do |w|
          findings << Finding.new(:error, "skill #{skill.name}: write '#{w}' overlaps protected '#{protected}'") if overlap?(w, protected)
        end
      end
      denies = Array(perms["deny_read"]).flat_map { |p| @plane.expand(p) }
      evals = @plane.path_groups.fetch("HARNESS_EVALS", [])
      findings << Finding.new(:error, "skill #{skill.name}: must deny_read ${HARNESS_EVALS}") unless evals.all? { |e| denies.include?(e) }
      findings
    end

    # Two `**` globs overlap when either prefix contains the other.
    def overlap?(a, b)
      pa = a.delete_suffix("/**")
      pb = b.delete_suffix("/**")
      a == "**" || b == "**" || pa == pb || pa.start_with?("#{pb}/") || pb.start_with?("#{pa}/")
    end
  end
end
