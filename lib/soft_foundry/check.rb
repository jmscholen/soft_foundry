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
      findings.concat(check_accessibility_standard)
      findings.concat(check_policy_standard)
      findings.concat(check_path_groups)
      findings.concat(check_transitions)
      findings.concat(check_tracks)
      @plane.phases.each { |phase| findings.concat(check_phase(phase)) }
      findings
    end

    private

    def check_templates
      %w[templates/handoff.yml templates/change/metadata.yml].reject { |f| File.exist?(File.join(@plane.dir, f)) }
                                                              .map { |f| Finding.new(:error, ".ai/#{f} is missing") }
    end

    # A warning, not an error: the plane still works without the standard,
    # but every accessibility review in it would have nothing to cite.
    def check_accessibility_standard
      return [] if File.exist?(File.join(@plane.dir, "rules", "accessibility.md"))
      [Finding.new(:warning, ".ai/rules/accessibility.md is missing; accessibility reviews have no standard to cite (advisory only)")]
    end

    # Same shape: the governed application's published promises can only be
    # reviewed against a standard that says how.
    def check_policy_standard
      return [] if File.exist?(File.join(@plane.dir, "rules", "policy-conformance.md"))
      [Finding.new(:warning, ".ai/rules/policy-conformance.md is missing; privacy and security policy conformance reviews have no standard to cite (advisory only)")]
    end

    def check_path_groups
      missing = ControlPlane::REQUIRED_GROUPS - @plane.path_groups.keys
      findings = missing.map { |g| Finding.new(:error, "paths.yml lacks required group #{g}") }
      (ControlPlane::REQUIRED_GROUPS - missing).each do |g|
        findings << Finding.new(:error, "path group #{g} resolves to no patterns (check repository.yml overrides)") if @plane.path_groups[g].empty?
      end
      @plane.override_path_groups.each do |g, globs|
        if ControlPlane::PROTECTED_GROUPS.include?(g)
          findings << Finding.new(:error, "repository.yml overrides protected path group #{g}; the default is kept and the override must be removed")
          next
        end
        next unless ControlPlane::REQUIRED_GROUPS.include?(g)
        defaults = @plane.default_path_groups.fetch(g, [])
        if @plane.files_matching(globs).empty? && !@plane.files_matching(defaults).empty?
          findings << Finding.new(:error, "repository.yml override for #{g} matches no files while the default patterns do; staleness and permissions would be blind")
        end
      end
      findings
    rescue Errno::ENOENT
      [Finding.new(:error, ".ai/paths.yml is missing")]
    end

    def check_transitions
      ids = @plane.phases.map(&:id)
      after_problems = @plane.phases.filter_map do |p|
        Finding.new(:error, "lifecycle: '#{p.id}' has after: '#{p.after}' which is not a lifecycle phase") if p.after && !ids.include?(p.after)
      end
      after_problems + @plane.transitions.flat_map do |from, edges|
        problems = []
        problems << Finding.new(:error, "transitions: '#{from}' is not a lifecycle phase") unless ids.include?(from)
        Hash(edges).each_value { |to| problems << Finding.new(:error, "transitions: '#{from}' targets unknown phase '#{to}'") unless ids.include?(to) }
        problems
      end
    end

    # Tracks (.ai/workflow.yml tracks:): the default and any risk-forced
    # track must be defined, every phase a track names must exist, and an
    # exploring track's skill must be a complete contract that cannot write
    # commit-bound evidence, because the exploring stage produces none.
    def check_tracks
      raw = @plane.workflow["tracks"]
      return [] if raw.nil?
      return [Finding.new(:error, "workflow.yml: tracks must be a mapping")] unless raw.is_a?(Hash)

      findings = []
      ids = @plane.phases.map(&:id)
      findings << Finding.new(:error, "tracks: default '#{@plane.default_track}' is not a defined track") unless @plane.track(@plane.default_track)
      Hash(raw["forced_by_risk"]).each do |risk, name|
        findings << Finding.new(:error, "tracks: forced_by_risk #{risk} names unknown track '#{name}'") unless @plane.track(name)
      end
      @plane.tracks.each_value do |track|
        (track.vet_requires + track.optional).each do |id|
          findings << Finding.new(:error, "tracks: #{track.name} references unknown phase '#{id}'") unless ids.include?(id)
        end
        next unless track.exploring?
        if track.skill.to_s.empty? || track.output.to_s.empty?
          findings << Finding.new(:error, "tracks: #{track.name} is exploring but does not name both a skill and an output directory")
          next
        end
        findings.concat(check_skill_contract(track.skill, "track #{track.name}", phase: false))
        findings.concat(check_exploring_writes(track))
      end
      findings
    end

    def check_exploring_writes(track)
      return [] unless File.directory?(File.join(@plane.dir, "skills", track.skill))
      skill = @plane.skill(track.skill)
      writes = Array(skill.permissions["write"]).flat_map { |p| @plane.expand(p) }
      @plane.phases.flat_map do |phase|
        next [] unless File.directory?(File.join(@plane.dir, "skills", phase.skill)) && @plane.skill(phase.skill).commit_bound?
        evidence = "changes/CHANGE/#{phase.output}/**"
        writes.select { |w| overlap?(w, evidence) }
              .map { |w| Finding.new(:error, "skill #{skill.name}: write '#{w}' overlaps commit-bound evidence '#{evidence}'; the exploring stage produces no evidence") }
      end
    rescue ArgumentError => e
      [Finding.new(:error, "skill #{track.skill}: #{e.message}")]
    end

    def check_phase(phase)
      check_skill_contract(phase.skill, "phase #{phase.id}", phase: true)
    end

    # A skill's contract files, profile, templates, and permissions. A phase
    # skill's completion must require handoff.yml; a stage skill (an
    # exploring track's) has no handoff, its completion is `change vet`.
    def check_skill_contract(name, owner, phase:)
      skill_dir = File.join(@plane.dir, "skills", name)
      return [Finding.new(:error, "#{owner}: skill directory '#{name}' is missing")] unless File.directory?(skill_dir)

      missing = ControlPlane::SKILL_FILES.reject { |f| File.exist?(File.join(skill_dir, f)) }
      return missing.map { |f| Finding.new(:error, "skill #{name}: #{f} is missing") } unless missing.empty?

      skill = @plane.skill(name)
      findings = []
      findings << Finding.new(:error, "skill #{skill.name}: skill.yml name is '#{skill.definition['name']}'") unless skill.definition["name"] == skill.name
      findings << Finding.new(:error, "skill #{skill.name}: profile '#{skill.profile}' has no .ai/profiles definition") unless @plane.profile_names.include?(skill.profile)
      findings << Finding.new(:error, "skill #{skill.name}: completion.yml must require handoff.yml") if phase && !skill.required_files.include?("handoff.yml")
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
