# frozen_string_literal: true

require_relative "control_plane"

module SoftFoundry
  # Go-live advisories for one change record: things a person should know
  # about before the change ships, printed alongside gate results and on
  # `change close`, and deliberately never a gate failure. The lifecycle
  # gates decide whether a phase's evidence is complete; the advisory
  # decides nothing, it only names what was skipped, waived, or left "N/A"
  # so that the human making the go-live call is not surprised later.
  #
  # Today it covers the accessibility standard (.ai/rules/accessibility.md),
  # the privacy and security policy conformance standard
  # (.ai/rules/policy-conformance.md, checked against what the governed
  # application has published), and the independent-review and
  # final-judgment phases, because those are the places where a change's
  # own skipped_phases can quietly remove the check that would otherwise
  # have caught a user-facing defect or a broken promise.
  class Advisory
    Notice = Data.define(:area, :message)

    # Frameworks whose presence in .ai/repository.yml means the repository
    # renders something a person perceives or operates.
    UI_FRAMEWORKS = %w[rails sinatra express next react vue angular django flask fastapi].freeze

    # The published documents .ai/repository.yml records under policies:.
    POLICY_DOCUMENTS = %w[privacy security terms].freeze

    ACCESSIBILITY_RULE = ".ai/rules/accessibility.md"
    POLICY_RULE = ".ai/rules/policy-conformance.md"
    PLACEHOLDER = /\bTBD\b/
    NOT_APPLICABLE = /\bN\/A\b/i

    # UI frameworks a repository profile records, sorted so anything printed
    # from the list is order-independent.
    def self.ui_frameworks(plane)
      (Array(plane.repository_profile.dig("technology", "frameworks")).map(&:to_s) & UI_FRAMEWORKS).sort
    end

    # Published policy documents a repository profile records as found
    # (status PASS), by name. MISSING, UNKNOWN, and NOT_APPLICABLE entries
    # are real answers too, but there is no document behind them to check
    # a change against.
    def self.policy_documents(plane)
      policies = plane.repository_profile["policies"]
      return [] unless policies.is_a?(Hash)
      POLICY_DOCUMENTS.select { |name| policies[name].is_a?(Hash) && policies[name]["status"].to_s == "PASS" }
    end

    def initialize(record)
      @record = record
      @plane = record.control_plane
    end

    def notices
      notices = []
      notices.concat(skipped_phase_notices)
      notices.concat(environment_notices)
      notices.concat(accessibility_notices)
      notices.concat(policy_notices)
      notices
    end

    # The development environment recorded in .ai/repository.yml, or nil.
    def development_environment
      env = @plane.repository_profile.dig("environments", "development")
      env.is_a?(Hash) ? env : nil
    end

    # The rationale a change gave for skipping a phase, or nil when the
    # phase is not in skipped_phases (an entry with an empty rationale
    # does not count as a skip, mirroring Gate#predecessor_check).
    def skip_rationale(phase_id)
      entry = Array(@record.metadata["skipped_phases"]).find { |e| e["phase"] == phase_id && e["rationale"].to_s.strip != "" }
      entry && entry["rationale"].to_s.strip
    end

    def accessibility_surface?
      @record.metadata.dig("surfaces", "accessibility") == true
    end

    def policy_surface?
      @record.metadata.dig("surfaces", "policy") == true
    end

    def repository_ui_frameworks = self.class.ui_frameworks(@plane)
    def repository_policy_documents = self.class.policy_documents(@plane)

    # Human-boundary decisions recorded in metadata.yml that a person has
    # actually made (decided_by filled in), optionally for one boundary.
    def human_decisions(boundary = nil)
      Array(@record.metadata["human_decisions"]).select do |d|
        d.is_a?(Hash) && d["decided_by"].to_s.strip != "" && !d["decided_by"].to_s.match?(PLACEHOLDER) &&
          (boundary.nil? || d["boundary"].to_s == boundary)
      end
    end

    private

    def skipped_phase_notices
      notices = []
      if (why = skip_rationale("review"))
        notices << Notice.new("review", "independent review was skipped (#{why}); accessibility, policy, security, and coding-standard conformance were not independently checked")
      end
      if (why = skip_rationale("judge"))
        notices << Notice.new("judgment", "final judgment was skipped (#{why}); no APPROVED/BLOCKED/REJECTED verdict exists for this change")
      end
      notices
    end

    # An exploring track deploys each round to the development environment;
    # a repository whose profile records none gives the stage nowhere to
    # put the feature in front of a person. Reported, never a gate failure:
    # a change that cannot deploy (a library, say) still explores by other
    # means and says so in its journal.
    def environment_notices
      return [] unless @record.track_definition&.exploring?
      env = development_environment
      status = env && env["status"].to_s
      return [] if status == "PASS" || status == "NOT_APPLICABLE"
      [Notice.new("environment", "the #{@record.track} track deploys the exploring stage to the development environment, but .ai/repository.yml records #{env ? "it as #{status.empty? ? 'unset' : status}" : 'none'} under environments:; discovery must record where the feature is put in front of a person (NOT_APPLICABLE with a rationale is a valid answer)")]
    end

    def accessibility_notices
      notices = []
      unless File.file?(File.join(@record.root, ACCESSIBILITY_RULE))
        notices << Notice.new("accessibility", "no accessibility standard is in force (#{ACCESSIBILITY_RULE} is missing), so review has nothing to cite")
      end

      unless accessibility_surface?
        frameworks = repository_ui_frameworks
        unless frameworks.empty?
          notices << Notice.new("accessibility", "repository has a user-facing framework (#{frameworks.join(', ')}) but this change declares surfaces.accessibility: false; confirm it touches nothing a person perceives or operates, or set the flag so the accessibility checks apply")
        end
        return notices
      end

      notices.concat(requirement_notices("accessibility", "accessibility", "an accessibility surface"))
      notices.concat(evaluation_notices)
      notices.concat(review_notices)
      notices
    end

    # What the governed application has promised in its privacy policy,
    # security policy, or terms, and whether this change was checked
    # against it. Publishing a change to those documents is a legal
    # commitment (.ai/policies/human-boundaries.yml): the review lists what
    # is owed, a person decides, and the decision lives in metadata.yml.
    def policy_notices
      notices = []
      unless File.file?(File.join(@record.root, POLICY_RULE))
        notices << Notice.new("policy", "no privacy and security policy conformance standard is in force (#{POLICY_RULE} is missing), so review has nothing to cite")
      end

      documents = repository_policy_documents
      unless policy_surface?
        unless documents.empty?
          notices << Notice.new("policy", "repository profile records published policy documents (#{documents.join(', ')}) but this change declares surfaces.policy: false; confirm it alters nothing the application collects, shares, retains, protects, or promises, or set the flag so the policy-conformance checks apply")
        end
        return notices
      end

      if documents.empty?
        notices << Notice.new("policy", ".ai/repository.yml records no published privacy, security, or terms document under policies: although the change declares a policy surface; discovery must record what the application publishes (MISSING is a valid, visible answer) and review must say what it checked against")
      end
      notices.concat(requirement_notices("policy", "policy", "a policy surface"))
      notices.concat(policy_review_notices)
      notices
    end

    # A completed specification must carry at least one requirement of the
    # given category when the surface is declared; a skipped specification
    # leaves review with nothing to check conformance against.
    def requirement_notices(area, category, surface)
      phase = @plane.phase("specify")
      return [] unless phase
      if skip_rationale("specify")
        return [Notice.new(area, "no #{area} requirements were recorded: the specification phase was skipped, so there is nothing for review to check conformance against")]
      end
      return [] unless @record.phase_status(phase) == "complete"
      path = File.join(@record.phase_dir(phase), "requirements.yml")
      return [] unless File.file?(path)
      reqs = Array(load(path)["requirements"])
      return [] if reqs.any? { |r| r.is_a?(Hash) && r["category"].to_s == category }
      [Notice.new(area, "02-specification/requirements.yml has no requirement with category: #{category} although the change declares #{surface}")]
    end

    def evaluation_notices
      phase = @plane.phase("evaluate")
      return [] unless phase && @record.phase_status(phase) == "complete"
      section = section_body(File.join(@record.phase_dir(phase), "results.md"), "Accessibility observations")
      return [] if section.nil?
      return [] unless section.empty? || section.match?(PLACEHOLDER) || section.match?(NOT_APPLICABLE)
      [Notice.new("accessibility", "07-evaluation/results.md records no accessibility observations (empty, TBD, or N/A) although the change declares an accessibility surface")]
    end

    def review_notices
      phase = @plane.phase("review")
      return [] unless phase
      if skip_rationale("review")
        return [Notice.new("accessibility", "no accessibility review exists: the review phase was skipped although the change declares an accessibility surface")]
      end
      status = @record.phase_status(phase)
      return [Notice.new("accessibility", "the accessibility review (13-review/accessibility.md) has not run yet")] unless status == "complete"
      path = File.join(@record.phase_dir(phase), "accessibility.md")
      return [Notice.new("accessibility", "13-review/accessibility.md is missing")] unless File.file?(path)
      body = File.read(path)
      conformance = section_body(path, "Conformance").to_s
      if body.match?(PLACEHOLDER)
        [Notice.new("accessibility", "13-review/accessibility.md still contains TBD placeholders")]
      elsif conformance.match?(NOT_APPLICABLE)
        [Notice.new("accessibility", "13-review/accessibility.md declares conformance N/A although the change declares an accessibility surface")]
      else
        []
      end
    end

    def policy_review_notices
      phase = @plane.phase("review")
      return [] unless phase
      if skip_rationale("review")
        return [Notice.new("policy", "no policy-conformance review exists: the review phase was skipped although the change declares a policy surface")]
      end
      status = @record.phase_status(phase)
      return [Notice.new("policy", "the policy-conformance review (13-review/policy-conformance.md) has not run yet")] unless status == "complete"
      path = File.join(@record.phase_dir(phase), "policy-conformance.md")
      return [Notice.new("policy", "13-review/policy-conformance.md is missing")] unless File.file?(path)
      return [Notice.new("policy", "13-review/policy-conformance.md still contains TBD placeholders")] if File.read(path).match?(PLACEHOLDER)
      notices = []
      if section_body(path, "Conformance").to_s.match?(NOT_APPLICABLE)
        notices << Notice.new("policy", "13-review/policy-conformance.md declares conformance N/A although the change declares a policy surface")
      end
      notices.concat(policy_text_change_notices(path))
      notices
    end

    # A review that lists policy text changes owed has found a legal
    # commitment. Until a person's decision is recorded under
    # human_decisions, the change is parked, and the advisory says so
    # whether or not the record's status reflects that yet.
    def policy_text_change_notices(path)
      owed = section_body(path, "Policy text changes required").to_s
      return [] if owed.empty? || owed.match?(/\Anone\b/i)
      return [] unless human_decisions("legal commitment").empty?
      if @record.metadata["status"].to_s == "awaiting_human"
        [Notice.new("policy", "parked awaiting a person's decision on the policy text changes listed in 13-review/policy-conformance.md (a legal commitment); record it under human_decisions in metadata.yml once made")]
      else
        [Notice.new("policy", "13-review/policy-conformance.md lists policy text changes owed; publishing them is a legal commitment awaiting a person: park the change with status: awaiting_human and record the decision under human_decisions in metadata.yml")]
      end
    end

    # The text under a "## Heading" up to the next "## ", stripped; nil
    # when the file or heading is absent.
    def section_body(path, heading)
      return nil unless File.file?(path)
      lines = File.read(path).lines
      start = lines.index { |l| l.strip == "## #{heading}" }
      return nil unless start
      body = lines[(start + 1)..].take_while { |l| !l.start_with?("## ") }
      body.join.strip
    end

    def load(path)
      YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
    rescue Psych::Exception
      {}
    end
  end
end
