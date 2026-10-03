# frozen_string_literal: true

require "time"
require "date"
require_relative "control_plane"
require_relative "change_record"
require_relative "change_index"
require_relative "gate"
require_relative "advisory"
require_relative "budget"

module SoftFoundry
  # The state of the workflow and of each change record as plain data
  # (string-keyed Hashes, Arrays, strings, numbers, booleans, nil), ready
  # to serialize. It reads what the gate, advisory, and budget already
  # compute and decides nothing itself. Timestamps are ISO-8601 strings,
  # paths are repository-relative, and no file's content is included.
  class Snapshot
    VERSION = 1

    # How a change stands on its lifecycle track: what `change status`
    # prints as the track line, as data.
    def self.track(record)
      definition = record.track_definition
      iterations = record.iterations
      deployed = iterations.last && iterations.last["deployed"]
      vetted = record.vetted
      {
        "name" => record.track,
        "defined" => !definition.nil?,
        "exploring_stage" => definition ? definition.exploring? : false,
        "exploring" => record.exploring?,
        "iterations" => iterations.size,
        "last_deployed" => deployed.is_a?(Hash) && deployed["environment"] ? plain(deployed["environment"]).to_s : nil,
        "vetted" => vetted && { "at" => stamp(vetted["at"]), "by" => plain(vetted["by"].to_s), "commit" => plain(vetted["commit"].to_s) },
        "forced_by_risk" => record.control_plane.track_forced_by_risk(record.metadata["risk"])
      }
    end

    # A recorded time as an ISO-8601 string. YAML hands back a Time for an
    # unquoted timestamp and a String for a quoted one; both are kept as
    # what was recorded, never reinterpreted.
    def self.stamp(value)
      case value
      when nil then nil
      when Time then value.utc.iso8601
      when Date then value.iso8601
      else text = plain(value.to_s).strip
           text.empty? ? nil : text
      end
    end

    # Recorded YAML reduced to what JSON can carry.
    def self.plain(value)
      case value
      when Hash then value.to_h { |k, v| [plain(k.to_s), plain(v)] }
      when Array then value.map { |v| plain(v) }
      when String then value.encoding == Encoding::UTF_8 && value.valid_encoding? ? value : value.dup.force_encoding(Encoding::UTF_8).scrub("?")
      when Time, Date then stamp(value)
      when Integer, true, false, nil then value
      when Float then value.finite? ? value : nil
      else plain(value.to_s)
      end
    end

    def initialize(root, plane:, git:, index: nil)
      @root = File.expand_path(root)
      @plane = plane
      @git = git
      @index = index || ChangeIndex.new(@root, plane: plane, git: git)
    end

    # The lifecycle itself, independent of any change.
    def workflow
      {
        "version" => VERSION,
        "name" => plain(@plane.workflow["name"]),
        "phases" => @plane.phases.map { |phase| workflow_phase(phase) },
        "transitions" => plain(@plane.transitions),
        "rules" => plain(@plane.rules),
        "judgments" => plain(@plane.judgments),
        "check_descriptions" => Gate::CHECKS,
        "tracks" => {
          "default" => @plane.default_track,
          "forced_by_risk" => plain(@plane.tracks_raw["forced_by_risk"].is_a?(Hash) ? @plane.tracks_raw["forced_by_risk"] : {}),
          "list" => @plane.tracks.values.map do |t|
            { "name" => t.name, "description" => plain(t.description), "exploring" => t.exploring?, "skill" => t.skill, "output" => t.output,
              "vet_requires" => t.vet_requires, "optional" => t.optional }
          end
        }
      }
    end

    # Every change record, one row each with a cell per phase. Only
    # records that are not closed are gated, as in `ci`: a closed record is
    # settled history and its row reports what its handoffs recorded. A
    # record that cannot be read gets a row saying so.
    def board
      {
        "version" => VERSION,
        "generated_at" => now,
        "default_branch" => @index.default_branch,
        "phases" => @plane.phases.map { |p| { "id" => p.id, "output" => p.output, "optional" => p.optional } },
        "changes" => @index.slugs.map { |slug| board_row(slug) }
      }
    end

    # One change in full: every gate with its checks, the advisories, the
    # recorded history, and the spend ledger.
    def change(slug)
      record = @index.record(slug)
      meta = metadata(record)
      results = Gate.new(record, git: @git).evaluate_all
      summary(record, meta).merge(
        "version" => VERSION,
        "generated_at" => now,
        "branch" => plain(meta.dig("git", "branch")),
        "created_at" => self.class.stamp(meta["created_at"]),
        "surfaces" => plain(meta["surfaces"].is_a?(Hash) ? meta["surfaces"] : {}),
        "track" => self.class.track(record),
        "merged_unclosed" => @index.merged_unclosed?(record),
        "failed" => results.any?(&:failed?),
        "stale" => results.any?(&:stale?),
        "skipped_phases" => plain(Array(meta["skipped_phases"]).select { |e| e.is_a?(Hash) }),
        "human_decisions" => plain(Array(meta["human_decisions"]).select { |e| e.is_a?(Hash) }),
        "undischarged" => plain(@plane.phase("judge") ? record.undischarged_acceptance : []),
        "gates" => results.map { |result| gate(record, meta, result) },
        "advisories" => Advisory.new(record).notices.map { |n| { "area" => n.area.to_s, "message" => plain(n.message) } },
        "timeline" => timeline(record, meta),
        "spend" => spend(record, meta)
      )
    end

    private

    def plain(value) = self.class.plain(value)
    def now = Time.now.utc.iso8601

    # A record's metadata is whatever YAML someone put in that file; only
    # a mapping is a record.
    def metadata(record)
      meta = record.metadata
      raise "changes/#{record.slug}/metadata.yml is not a mapping" unless meta.is_a?(Hash)
      meta
    end

    def workflow_phase(phase)
      skill = @plane.skill(phase.skill)
      {
        "id" => phase.id, "output" => phase.output, "skill" => phase.skill,
        "optional" => phase.optional, "after" => phase.after,
        "hardening" => @plane.hardening_phase?(phase),
        "next" => @plane.transitions.dig(phase.id, "next") || @plane.successor(phase)&.id || "done",
        "profile" => plain(skill.profile),
        "commit_bound" => skill.commit_bound?,
        "required_files" => plain(skill.required_files),
        "blocking" => plain(skill.blocking_conditions),
        "checks" => Gate.checks_for(@plane, phase).map { |name| { "name" => name, "description" => Gate::CHECKS.fetch(name) } }
      }
    end

    def summary(record, meta)
      {
        "slug" => record.slug,
        "title" => plain(meta.dig("change", "title")),
        "status" => plain(meta["status"]),
        "current_phase" => plain(meta["current_phase"]),
        "risk" => plain(meta["risk"]),
        "type" => plain(meta["type"]),
        "closed" => meta["status"] == "closed"
      }
    end

    def board_row(slug)
      record = @index.record(slug)
      meta = metadata(record)
      row = summary(record, meta).merge("track" => record.track, "exploring" => record.exploring?)
      if row["closed"]
        return row.merge("evaluated" => false, "merged_unclosed" => false, "stale" => false, "failed" => false, "advisories" => nil,
                         "cells" => @plane.phases.map { |phase| recorded_cell(record, meta, phase) })
      end
      results = Gate.new(record, git: @git).evaluate_all
      row.merge("evaluated" => true, "merged_unclosed" => @index.merged_unclosed?(record),
                "stale" => results.any?(&:stale?), "failed" => results.any?(&:failed?),
                "advisories" => Advisory.new(record).notices.size,
                "cells" => results.map { |r| { "phase" => r.phase.id, "status" => r.status, "state" => state(r), "skip_reason" => skip_reason(record, meta, r.phase, r.status) } })
    rescue StandardError => e
      { "slug" => slug, "error" => relative(e.message) }
    end

    # A phase as its handoff records it, without running the gate.
    def recorded_cell(record, meta, phase)
      status = record.phase_status(phase).to_s
      status = "missing" unless ChangeRecord::STATUSES.include?(status)
      { "phase" => phase.id, "status" => status, "state" => status, "skip_reason" => skip_reason(record, meta, phase, status) }
    end

    # One word for where a gated phase stands: pass, warn, fail, stale,
    # in_progress, blocked, pending, or missing.
    def state(result)
      return "missing" if result.status == "missing"
      return result.stale? ? "stale" : "fail" if result.failed?
      return result.status if %w[pending in_progress blocked].include?(result.status)
      result.checks.any? { |c| c.outcome == :warn } ? "warn" : "pass"
    end

    # Why a pending phase may stay pending for this change, or nil when it
    # is still owed: waived in skipped_phases, not required by the track,
    # or optional for every change.
    def skip_reason(record, meta, phase, status)
      return nil unless status == "pending"
      return "waived" if skip_rationale(meta, phase)
      return "track" if Array(record.track_definition&.optional).include?(phase.id)
      phase.optional ? "optional" : nil
    end

    def skip_rationale(meta, phase)
      entry = Array(meta["skipped_phases"]).find { |e| e.is_a?(Hash) && e["phase"] == phase.id && e["rationale"].to_s.strip != "" }
      entry && plain(entry["rationale"].to_s.strip)
    end

    def gate(record, meta, result)
      phase = result.phase
      handoff = record.handoff(phase) || {}
      {
        "phase" => phase.id, "output" => phase.output, "skill" => phase.skill,
        "status" => result.status, "state" => state(result),
        "skip_reason" => skip_reason(record, meta, phase, result.status),
        "skip_rationale" => result.status == "pending" ? skip_rationale(meta, phase) : nil,
        "started_at" => self.class.stamp(handoff["started_at"]),
        "completed_at" => self.class.stamp(handoff["completed_at"]),
        "commit_sha" => plain(handoff["commit_sha"]),
        "executed_by" => handoff["executed_by"].is_a?(Hash) ? plain(handoff["executed_by"]) : nil,
        "blocking" => plain(Array(handoff["blocking"])),
        "findings" => plain(Array(handoff["findings"]).select { |f| f.is_a?(Hash) }),
        "checks" => result.checks.map { |c| { "name" => c.name, "outcome" => c.outcome.to_s, "detail" => plain(c.detail.to_s) } }
      }
    end

    # What the record says happened, oldest first. Only recorded times are
    # used; an event with no time recorded, or with a placeholder or free
    # text where a time belongs, is left out rather than guessed at.
    def timeline(record, meta)
      events = []
      add = lambda do |at, kind, label, phase = nil|
        at = self.class.stamp(at)
        events << { "at" => at, "kind" => kind, "phase" => phase, "label" => plain(label) } if at && sortable(at)
      end
      add.call(meta["created_at"], "created", "change record created")
      @plane.phases.each do |phase|
        handoff = record.handoff(phase) or next
        add.call(handoff["started_at"], "started", "#{phase.output} started", phase.id)
        add.call(handoff["completed_at"], "completed", "#{phase.output} completed", phase.id) if handoff["status"] == "complete"
      end
      record.iterations.each_with_index do |iteration, i|
        said = iteration["outcome"] || iteration["changed"] || iteration["asked"]
        add.call(iteration["at"], "iteration", "iteration #{i + 1}#{said.to_s.strip.empty? ? '' : ": #{said.to_s.strip}"}")
      end
      if (vetted = record.vetted)
        add.call(vetted["at"], "vetted", "vetted by #{vetted['by']} at #{vetted['commit'].to_s[0, 12]}; specification locked")
      end
      Array(meta["reopenings"]).select { |r| r.is_a?(Hash) }.each do |reopening|
        add.call(reopening["at"], "reopened", "reopened for exploring: #{reopening['reason']}")
      end
      Array(meta["human_decisions"]).select { |d| d.is_a?(Hash) }.each do |decision|
        add.call(decision["decided_at"], "human_decision", "#{decision['boundary']}: #{decision['subject']} #{decision['decision']} by #{decision['decided_by']}")
      end
      Budget.new(record).entries.each do |entry|
        cost = entry.estimated_usd ? format(", $%.2f", entry.estimated_usd) : ""
        add.call(entry.recorded_at, "spend", "#{entry.provider}/#{entry.model}: #{entry.tokens_in} in, #{entry.tokens_out} out#{cost}", phase_id(entry.phase))
      end
      events.each_with_index.sort_by { |event, i| [sortable(event["at"]), i] }.map(&:first)
    end

    # A recorded time as a number to order by, or nil when what was
    # recorded is not a date.
    def sortable(at)
      at.match?(/\A\d{4}-\d\d-\d\d/) ? Time.parse(at).to_f : nil
    rescue ArgumentError
      nil
    end

    def over?(amount, cap) = !amount.nil? && !cap.nil? && amount > cap

    # A ledger entry names its phase by id or by output directory.
    def phase_id(key) = @plane.phase(key.to_s)&.id || plain(key.to_s)

    def spend(record, meta)
      budget = Budget.new(record)
      entries = budget.entries
      totals = budget.totals
      risk = meta["risk"].to_s
      policy = begin
        Budget.policy(@plane, risk: risk.empty? || risk.match?(Gate::PLACEHOLDER) ? nil : risk)
      rescue StandardError
        nil
      end
      {
        "totals" => { "tokens_in" => totals.tokens_in, "tokens_out" => totals.tokens_out, "estimated_usd" => totals.estimated_usd,
                      "entries_missing_cost" => totals.entries_missing_cost,
                      "over_cap" => over?(totals.estimated_usd, policy&.max_usd_per_change),
                      "needs_approval" => over?(totals.estimated_usd, policy&.require_human_approval_above_usd) },
        "policy" => policy && { "max_usd_per_change" => policy.max_usd_per_change, "max_usd_per_phase" => policy.max_usd_per_phase,
                                "require_human_approval_above_usd" => policy.require_human_approval_above_usd },
        "by_phase" => entries.group_by { |e| phase_id(e.phase) }.map do |phase, list|
          priced = list.filter_map(&:estimated_usd)
          { "phase" => phase, "tokens_in" => list.sum(&:tokens_in), "tokens_out" => list.sum(&:tokens_out),
            "estimated_usd" => priced.empty? ? nil : priced.sum, "entries" => list.size,
            "over_cap" => over?(priced.empty? ? nil : priced.sum, policy&.max_usd_per_phase) }
        end,
        "entries" => entries.map do |e|
          { "phase" => phase_id(e.phase), "provider" => plain(e.provider), "model" => plain(e.model), "tokens_in" => e.tokens_in,
            "tokens_out" => e.tokens_out, "estimated_usd" => e.estimated_usd, "recorded_at" => self.class.stamp(e.recorded_at),
            "recorded_by" => plain(e.recorded_by) }
        end
      }
    end

    def relative(text) = plain(text.to_s).gsub("#{@root}/", "")
  end
end
