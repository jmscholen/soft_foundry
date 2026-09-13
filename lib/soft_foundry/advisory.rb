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
  # Today it covers the accessibility standard (.ai/rules/accessibility.md)
  # and the independent-review and final-judgment phases, because those
  # are the places where a change's own skipped_phases can quietly remove
  # the check that would otherwise have caught a user-facing defect.
  class Advisory
    Notice = Data.define(:area, :message)

    # Frameworks whose presence in .ai/repository.yml means the repository
    # renders something a person perceives or operates.
    UI_FRAMEWORKS = %w[rails sinatra express next react vue angular django flask fastapi].freeze

    ACCESSIBILITY_RULE = ".ai/rules/accessibility.md"
    PLACEHOLDER = /\bTBD\b/
    NOT_APPLICABLE = /\bN\/A\b/i

    def initialize(record)
      @record = record
      @plane = record.control_plane
    end

    def notices
      notices = []
      notices.concat(skipped_phase_notices)
      notices.concat(accessibility_notices)
      notices
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

    # UI frameworks the repository profile records, so an advisory can say
    # when a change in a UI-bearing repository has not declared the surface.
    def repository_ui_frameworks
      profile = @plane.repository_profile
      (Array(profile.dig("technology", "frameworks")).map(&:to_s) & UI_FRAMEWORKS).sort
    end

    private

    def skipped_phase_notices
      notices = []
      if (why = skip_rationale("review"))
        notices << Notice.new("review", "independent review was skipped (#{why}); accessibility, security, and coding-standard conformance were not independently checked")
      end
      if (why = skip_rationale("judge"))
        notices << Notice.new("judgment", "final judgment was skipped (#{why}); no APPROVED/BLOCKED/REJECTED verdict exists for this change")
      end
      notices
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

      notices.concat(specification_notices)
      notices.concat(evaluation_notices)
      notices.concat(review_notices)
      notices
    end

    def specification_notices
      phase = @plane.phase("specify")
      return [] unless phase
      if skip_rationale("specify")
        return [Notice.new("accessibility", "no accessibility requirements were recorded: the specification phase was skipped, so there is nothing for review to check conformance against")]
      end
      return [] unless @record.phase_status(phase) == "complete"
      path = File.join(@record.phase_dir(phase), "requirements.yml")
      return [] unless File.file?(path)
      reqs = Array(load(path)["requirements"])
      return [] if reqs.any? { |r| r.is_a?(Hash) && r["category"].to_s == "accessibility" }
      [Notice.new("accessibility", "02-specification/requirements.yml has no requirement with category: accessibility although the change declares an accessibility surface")]
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
