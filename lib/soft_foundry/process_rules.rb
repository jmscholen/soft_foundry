# frozen_string_literal: true

require "yaml"
require_relative "errors"

module SoftFoundry
  # The rules that keep a change converging (changes/process-speed): a cap
  # on remediation rounds that only a person's recorded decision passes,
  # acceptance criteria tiered must or should with a person approving the
  # must list, default waivers at low risk, and what counts as a
  # documentation-only path. Every answer is read from the record, the
  # control plane, or git; none is judged.
  #
  # A record carries `rules: 2` from `change new`. One without it is a
  # legacy record: the rules here do not apply to it, and each gate check
  # built on them reports skip with LEGACY.
  class ProcessRules
    VERSION = 2
    LEGACY = "legacy record: created before the convergence rules (no `rules: #{VERSION}` in metadata.yml)"
    DEFAULT_MAX_ROUNDS = 2
    DEFAULT_MUST_CAP = { "low" => 3, "medium" => 8, "high" => 15 }.freeze
    DEFAULT_WAIVER_RISKS = %w[low].freeze
    TIERS = %w[must should].freeze
    CAP_BOUNDARY = "remediation cap"
    APPROVAL_BOUNDARY = "must criteria approval"
    CAP_DECISIONS = %w[accept_residual narrow reject].freeze
    # A documentation-only remediation keeps these phases' evidence.
    DOCS_ONLY_KEPT = %w[verify evaluate attack].freeze
    REMEDIATE = "remediate"

    def initialize(record, git: nil)
      @record = record
      @plane = record.control_plane
      @git = git
    end

    def applies? = self.class.applies?(@record.metadata)

    def self.applies?(meta)
      value = meta.is_a?(Hash) ? meta["rules"] : nil
      value.is_a?(Integer) && value >= VERSION
    end

    # --- control-plane values -------------------------------------------

    # The remediation rounds a change may seal before a person decides.
    def max_rounds = self.class.max_rounds(@plane)

    def self.max_rounds(plane)
      raw = plane.workflow["remediation"]
      return DEFAULT_MAX_ROUNDS if raw.nil?
      value = raw.is_a?(Hash) ? raw["max_rounds"] : nil
      return DEFAULT_MAX_ROUNDS if raw.is_a?(Hash) && !raw.key?("max_rounds")
      return value if value.is_a?(Integer) && value >= 1
      raise TargetError, ".ai/workflow.yml remediation.max_rounds must be a whole number of 1 or more; it is #{value.inspect}"
    end

    # The most must criteria a change of `risk` may declare; nil when the
    # risk is not one the cap names (the tier check then names the risk).
    def must_cap(risk) = self.class.must_caps(@plane)[risk.to_s.strip.downcase]

    def self.must_caps(plane)
      raw = plane.workflow["must_criteria_cap"]
      return DEFAULT_MUST_CAP if raw.nil?
      unless raw.is_a?(Hash) && !raw.empty? && raw.all? { |k, v| k.is_a?(String) && v.is_a?(Integer) && v >= 1 }
        raise TargetError, ".ai/workflow.yml must_criteria_cap must map each risk to a whole number of 1 or more; it is #{raw.inspect}"
      end
      raw
    end

    # Risks whose waivable phases are stepped over unless run_phases asks.
    def self.default_waiver_risks(plane)
      raw = plane.workflow["default_waivers"]
      return DEFAULT_WAIVER_RISKS if raw.nil?
      return raw.map(&:to_s) if raw.is_a?(Array) && raw.all? { |r| r.is_a?(String) }
      raise TargetError, ".ai/workflow.yml default_waivers must be a list of risks; it is #{raw.inspect}"
    end

    # Problems with the three keys, for `check`. Empty when well formed.
    def self.lint(plane)
      %i[max_rounds must_caps default_waiver_risks].filter_map do |reader|
        send(reader, plane)
        nil
      rescue TargetError => e
        e.message
      end
    end

    # --- remediation rounds ---------------------------------------------

    # Sealed remediation rounds: the larger of the `Record <slug> remediate`
    # commits reachable from the record's branch (or HEAD) and the reopen
    # entries that reset a complete remediation. Git history and the
    # record must both be rewritten to lower it (THREAT-002).
    def remediation_rounds = [sealed_round_commits, reopened_rounds].max

    def sealed_round_commits
      return 0 unless @git&.repository?
      tip = @git.branch_tip(@record.git_branch) || "HEAD"
      @git.count_subject("Record #{@record.slug} #{REMEDIATE}", tip)
    end

    def reopened_rounds
      Array(@record.metadata["phase_reopenings"]).count do |entry|
        next false unless entry.is_a?(Hash) && Array(entry["reset"]).map(&:to_s).include?(REMEDIATE)
        previous = entry["previous"].is_a?(Hash) ? entry["previous"][REMEDIATE] : nil
        status = previous.is_a?(Hash) ? previous["status"] : previous
        status.to_s == "complete"
      end
    end

    def decisions(boundary)
      Array(@record.metadata["human_decisions"]).select { |d| d.is_a?(Hash) && d["boundary"].to_s.strip == boundary }
    end

    # The person's answer to the cap at `rounds` sealed rounds, or nil.
    def cap_decision(rounds)
      decisions(CAP_BOUNDARY).find do |d|
        d["rounds"].is_a?(Integer) && d["rounds"] == rounds && CAP_DECISIONS.include?(d["decision"].to_s.strip)
      end
    end

    # Whether one more remediation round may start (or be sealed) now.
    def another_round_allowed?(rounds = remediation_rounds)
      return true if rounds < max_rounds
      decision = cap_decision(rounds)
      !decision.nil? && decision["decision"].to_s.strip != "reject"
    end

    # Round counts above the limit with no decision that let them through.
    def unanswered_rounds(rounds = remediation_rounds)
      (max_rounds...rounds).reject do |k|
        d = cap_decision(k)
        d && d["decision"].to_s.strip != "reject"
      end
    end

    def cap_refusal(rounds = remediation_rounds)
      rejected = cap_decision(rounds)&.fetch("decision", nil).to_s.strip == "reject"
      head = if rejected
               "#{@record.slug} was rejected at the remediation cap (#{rounds} rounds); judge it REJECTED instead of remediating again"
             else
               "#{@record.slug} has sealed #{rounds} remediation #{rounds == 1 ? 'round' : 'rounds'}, the limit in .ai/workflow.yml (remediation.max_rounds: #{max_rounds}); another round needs a person's decision"
             end
      "#{head}. The change is parked: status is awaiting_human. A person records under human_decisions in metadata.yml: " \
        "boundary: #{CAP_BOUNDARY}, rounds: #{rounds}, decision: accept_residual (judge with the open findings as residual risk), " \
        "narrow (record a requirement change that narrows the claim, then remediate once more) or reject (judge it REJECTED); " \
        "then sets status back to in_progress"
    end

    # --- acceptance criteria ----------------------------------------------

    def criteria
      data = acceptance_data
      Array(data["criteria"]).select { |c| c.is_a?(Hash) && !c["id"].to_s.empty? }
    end

    def person_checks
      Array(acceptance_data["person_checks"]).select { |c| c.is_a?(Hash) && !c["id"].to_s.empty? }
    end

    def tier(criterion) = criterion["tier"].to_s.strip.downcase
    def must_ids = criteria.select { |c| tier(c) == "must" }.map { |c| c["id"].to_s }.uniq
    def should_ids = criteria.select { |c| tier(c) == "should" }.map { |c| c["id"].to_s }.uniq

    def approval
      decisions(APPROVAL_BOUNDARY).select { |d| d["decision"].to_s.strip == "approved" }.last
    end

    # --- waivers ----------------------------------------------------------

    def run_phases = Array(@record.metadata["run_phases"]).map(&:to_s)

    # The phases stepped over by default for this record's risk.
    def default_waivers
      return [] unless applies?
      risk = @record.metadata["risk"].to_s.strip.downcase
      return [] unless self.class.default_waiver_risks(@plane).include?(risk)
      @plane.waivable_by_risk(risk) - run_phases
    end

    # --- documentation-only paths -----------------------------------------

    # Documentation is the DOCS path group, Markdown at the repository
    # root, and the change's own record. The control plane (.ai/) is never
    # documentation: it is instructions.
    def self.documentation_path?(plane, path, slug)
      path = path.to_s.delete_prefix("./")
      return false if path.empty? || path.start_with?(".ai/") || path == ".ai"
      return true if path.start_with?("changes/#{slug}/")
      return true if !path.include?("/") && path.downcase.end_with?(".md")
      ControlPlane.match_any?(path, Array(plane.path_groups["DOCS"]))
    end

    private

    def acceptance_data
      specify = @plane.phase("specify")
      return {} unless specify
      path = File.join(@record.phase_dir(specify), "acceptance-criteria.yml")
      return {} unless File.file?(path)
      data = YAML.safe_load_file(path, aliases: false)
      data.is_a?(Hash) ? data : {}
    rescue Psych::Exception, SystemCallError
      {}
    end
  end
end
