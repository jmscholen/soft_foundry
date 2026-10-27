# frozen_string_literal: true

require "time"
require_relative "control_plane"
require_relative "change_record"
require_relative "errors"
require_relative "text"

module SoftFoundry
  # Resets a lifecycle phase and everything downstream of it so each can be
  # run again, on any track. It changes state only: handoffs go back to
  # pending and one `phase_reopenings` entry records what was reset and why.
  # It never writes an evidence file, never marks a phase complete, and the
  # reset and the history entry are applied together or not at all.
  class PhaseReopen
    MARKER = "SOFT_FOUNDRY_PHASE"
    REOPENABLE = %w[intake in_progress judged].freeze
    Result = Data.define(:phase, :reset, :entry)

    def initialize(root, plane:, git:, record:)
      @root = File.expand_path(root)
      @plane = plane
      @git = git
      @record = record
    end

    # `source` is "manual" (the command) or "auto" (the runner, before a
    # session starts). Only a manual reopen is refused inside a phase-run
    # session, so a phase cannot reset another phase's handoff.
    def call(phase, reason:, source: "manual", env: ENV, now: Time.now)
      reason = Text.free_text!(reason, "--reason")
      refuse_marker!(env) if source == "manual"
      @record.locked { reopen(phase, reason, source, now) }
    end

    private

    def reopen(phase, reason, source, now)
      meta = @record.metadata
      status = meta["status"].to_s
      refuse_status!(status)
      reset = ([phase] + @plane.downstream(phase)).sort_by { |p| @plane.phases.index(p) }.select { |p| @record.phase_status(p) != "pending" }
      if reset.empty?
        raise TargetError, "nothing to reset: #{phase.id} and every phase after it are already pending; run `soft-foundry phase run #{phase.id}` instead"
      end
      stamp = now.utc.iso8601
      commit = @git.repository? ? @git.head_sha : nil
      entry = {
        "at" => stamp, "phase" => phase.id, "reset" => reset.map(&:id), "from_commit" => commit,
        "reason" => reason, "source" => source, "previous" => reset.to_h { |p| [p.id, previous(p)] }
      }
      @record.transaction do |tx|
        tx.metadata do |m|
          m["phase_reopenings"] = Array(m["phase_reopenings"]) + [entry]
          m["current_phase"] = phase.id
          m["status"] = "in_progress" if m["status"].to_s == "judged"
        end
        reset.each do |p|
          tx.handoff(p) do |h|
            h["status"] = "pending"
            h["commit_sha"] = nil
            h["completed_at"] = nil
            h["executed_by"] = nil
            h["outputs"] = []
            h["notes"] = [h["notes"].to_s, "reopened #{stamp} (#{source}): evidence files kept for reference; rerun this phase (#{reason})"].reject(&:empty?).join("\n")
          end
        end
      end
      Result.new(phase: phase, reset: reset, entry: entry)
    end

    def refuse_marker!(env)
      return unless env.key?(MARKER)
      raise TargetError, "phase reopen is refused inside a phase-run session (#{MARKER} is set): a phase may not reset another phase's handoff; ask the person running the change to run `soft-foundry phase reopen`"
    end

    def refuse_status!(status)
      return if REOPENABLE.include?(status)
      advice = case status
               when "closed" then "a merged change is reshaped by a new change, not by reopening its record"
               when "released" then "a released change is finished apart from its open items; discharge them with `soft-foundry change discharge`, or open a new change"
               when "exploring" then "an exploring change is reshaped with the person, and `soft-foundry change vet` ends it"
               when "awaiting_human" then "a person must record the decision under human_decisions in metadata.yml first"
               else "only a record that is #{REOPENABLE.join(', ')} can have a phase reopened"
               end
      raise TargetError, "#{@record.slug} is #{status}, so a phase cannot be reopened: #{advice}"
    end

    def previous(phase)
      h = @record.handoff(phase) || {}
      by = h["executed_by"].is_a?(Hash) ? h["executed_by"] : {}
      { "status" => h["status"], "commit_sha" => h["commit_sha"], "completed_at" => time_text(h["completed_at"]), "session_id" => by["session_id"] }
    end

    def time_text(value)
      value.respond_to?(:utc) ? value.utc.iso8601 : value
    end
  end
end
