# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"
require_relative "advisory"

module SoftFoundry
  # A durable `changes/<slug>/` record initialized from control-plane templates.
  class ChangeRecord
    STATUSES = %w[pending in_progress complete blocked].freeze

    attr_reader :root, :slug, :control_plane

    def self.create(root, slug, control_plane:, title: nil, branch: nil, worktree: nil, track: nil, now: Time.now)
      record = new(root, slug, control_plane: control_plane)
      raise "change record already exists: #{record.dir}" if record.exists?
      track ||= control_plane.default_track
      raise ArgumentError, "unknown track '#{track}'; .ai/workflow.yml defines: #{control_plane.track_names.join(', ')}" unless control_plane.track(track)
      record.send(:scaffold, title: title || slug, branch: branch || slug, worktree: worktree || root, track: track, now: now)
      record
    end

    def initialize(root, slug, control_plane:)
      raise ArgumentError, "invalid change slug '#{slug}'" unless slug.to_s.match?(/\A[A-Za-z0-9][A-Za-z0-9._\/-]*\z/) && !slug.include?("..")
      @root = File.expand_path(root)
      @slug = slug
      @control_plane = control_plane
    end

    def dir = File.join(root, "changes", slug)
    def exists? = File.exist?(File.join(dir, "metadata.yml"))
    def metadata = load(File.join(dir, "metadata.yml"))
    def phase_dir(phase) = File.join(dir, phase.output)
    def handoff_path(phase) = File.join(phase_dir(phase), "handoff.yml")

    def handoff(phase)
      path = handoff_path(phase)
      File.exist?(path) ? load(path) : nil
    end

    def phase_status(phase)
      handoff(phase)&.fetch("status", nil)
    end

    # The lifecycle track this change is on (.ai/workflow.yml tracks:). A
    # record written before tracks existed has none and is on the default.
    def track = (metadata["track"] || control_plane.default_track).to_s
    def track_definition = control_plane.track(track)
    def exploring? = metadata["status"].to_s == "exploring"

    # The person's recorded acceptance on an exploring track, or nil.
    def vetted
      v = metadata["vetted"]
      v.is_a?(Hash) ? v : nil
    end

    def exploration_dir
      output = track_definition&.output
      output && File.join(dir, output)
    end

    def iterations_path = exploration_dir && File.join(exploration_dir, "iterations.yml")

    # Entries in the exploring stage's journal, oldest first; empty when
    # the track has no exploring stage or nothing has been recorded.
    def iterations
      path = iterations_path
      return [] unless path && File.file?(path)
      Array(load(path)["iterations"]).select { |i| i.is_a?(Hash) }
    end

    # Phases this change's skipped_phases waive, each with a non-empty
    # rationale (an entry with an empty rationale does not count).
    def skipped_with_rationale
      Array(metadata["skipped_phases"]).filter_map { |e| e["phase"] if e.is_a?(Hash) && e["rationale"].to_s.strip != "" }
    end

    # A phase that may legitimately stay pending for this change: globally
    # optional, waived with rationale, or not required by the track.
    def skippable?(phase)
      phase.optional || skipped_with_rationale.include?(phase.id) || Array(track_definition&.optional).include?(phase.id)
    end

    # The commit_sha of the most-recently-completed phase, or nil if none
    # has run.
    def last_commit_sha
      sha = nil
      control_plane.phases.each do |phase|
        h = handoff(phase)
        sha = h["commit_sha"] if h && h["status"] == "complete" && h["commit_sha"]
      end
      sha
    end

    # True when every phase is either complete, or pending for a
    # legitimate reason (globally optional, or explicitly named in this
    # change's own skipped_phases with a non-empty rationale) - i.e.
    # nothing required is just sitting unaddressed. Mirrors the same
    # skip-aware logic Gate's predecessor_check already uses, because
    # this repo's own real changes (self-update, maturity-report,
    # observability-standard-dashboard, this one) routinely skip
    # discover/specify/threat_model/plan/attack/review/judge/learn with
    # rationale rather than completing them - "reached judgment" would
    # wrongly refuse to close every one of them.
    def reached_lifecycle_end?
      control_plane.phases.all? do |phase|
        status = phase_status(phase)
        status == "complete" || (status == "pending" && skippable?(phase))
      end
    end

    # The commit that represents this change's *finished* work, or nil if
    # it hasn't reached the end of its (possibly shortened) lifecycle yet.
    # Deliberately not just last_commit_sha unconditioned: an early
    # phase's commit_sha is just wherever the branch happened to fork
    # from, which is almost always already an ancestor of the default
    # branch - checking that unconditionally would call every early,
    # abandoned change "merged." Only once reached_lifecycle_end? is true
    # does "this commit is an ancestor of main" actually mean "this
    # change's work merged," which is what `ci` and `change close` need.
    def finished_commit_sha
      reached_lifecycle_end? ? last_commit_sha : nil
    end

    def judgment_evidence_path = File.join(phase_dir(control_plane.phase("judge")), "evidence.yml")
    def judgment_evidence = File.exist?(judgment_evidence_path) ? load(judgment_evidence_path) : {}

    # Acceptance criteria or judgment conditions left unsatisfied pending a
    # real-world event (production observation, etc.) rather than more
    # repository evidence. See the final-judgment evidence.yml template.
    def undischarged_acceptance = Array(judgment_evidence["undischarged"])

    # Moves `items` from undischarged to discharged, recording who/what
    # confirmed them. Never called with an item a human hasn't confirmed -
    # see CLI `change close`.
    def discharge!(items, confirmed_by:)
      data = judgment_evidence
      ids = items.map { |i| i["id"] }
      data["undischarged"] = Array(data["undischarged"]).reject { |i| ids.include?(i["id"]) }
      data["discharged"] = Array(data["discharged"]) + items.map { |i| i.merge("discharged_by" => confirmed_by) }
      File.write(judgment_evidence_path, YAML.dump(data))
    end

    # The mechanical half of closing a change's lifecycle: record the PR has
    # merged. Never call this if undischarged_acceptance is non-empty and
    # unconfirmed - see CLI `change close`.
    def close!
      path = File.join(dir, "metadata.yml")
      data = metadata
      data["status"] = "closed"
      data["current_phase"] = "done"
      File.write(path, YAML.dump(data))
    end

    # The person's acceptance of an explored feature: leaves exploring,
    # records who and at which commit, and from that commit the
    # specification is locked (Gate checks it) and the phases from
    # implement onward apply as on the gated track. The preconditions
    # (exploring, journal non-empty, vet_requires phases complete and
    # passing, specification committed) are the CLI's to check, since
    # they are what a person is told when refused.
    def vet!(by:, commit:, now: Time.now)
      path = File.join(dir, "metadata.yml")
      data = metadata
      data["status"] = "in_progress"
      data["current_phase"] = "implement"
      data["vetted"] = { "at" => now.utc.iso8601, "by" => by.to_s, "commit" => commit.to_s }
      File.write(path, YAML.dump(data))
    end

    # Sends a vetted change back to exploring. Every phase from implement
    # onward is reset to pending (its files stay in place, so nothing
    # observed is deleted), the vet is cleared, and the reopening is kept
    # in the record. Returns the phase output directories that were reset.
    def reopen!(reason:, now: Time.now)
      reset = control_plane.phases.select { |p| control_plane.hardening_phase?(p) && phase_status(p) != "pending" }
      stamp = now.utc.iso8601
      reset.each do |phase|
        h = handoff(phase)
        h["status"] = "pending"
        h["commit_sha"] = nil
        h["completed_at"] = nil
        h["notes"] = [h["notes"].to_s, "reopened #{stamp}: outputs kept for reference; rerun this phase after the next vet (#{reason})"].reject(&:empty?).join("\n")
        File.write(handoff_path(phase), YAML.dump(h))
      end
      path = File.join(dir, "metadata.yml")
      data = metadata
      data["reopenings"] = Array(data["reopenings"]) + [{ "at" => stamp, "from_commit" => vetted&.fetch("commit", nil), "reason" => reason.to_s }]
      data["vetted"] = nil
      data["status"] = "exploring"
      data["current_phase"] = "implement"
      File.write(path, YAML.dump(data))
      reset.map(&:output)
    end

    private

    def scaffold(title:, branch:, worktree:, track:, now:)
      FileUtils.mkdir_p(dir)
      definition = control_plane.track(track)
      write_template(File.join(control_plane.dir, "templates", "change", "metadata.yml"), File.join(dir, "metadata.yml"),
                     "CHANGE" => slug, "TITLE" => title, "BRANCH" => branch, "WORKTREE" => worktree, "CREATED_AT" => now.utc.iso8601,
                     "TRACK" => track, "STATUS" => definition.exploring? ? "exploring" : "intake",
                     "CURRENT_PHASE" => definition.exploring? ? "implement" : "intake")
      declare_surfaces!
      if definition.exploring?
        target = File.join(dir, definition.output)
        FileUtils.mkdir_p(target)
        copy_templates(control_plane.skill(definition.skill).template_dir, target)
      end
      write_template(File.join(control_plane.dir, "templates", "change", "budget.yml"), File.join(dir, "budget.yml"), "CHANGE" => slug)
      control_plane.phases.each do |phase|
        skill = control_plane.skill(phase.skill)
        target = phase_dir(phase)
        FileUtils.mkdir_p(target)
        copy_templates(skill.template_dir, target)
        write_template(File.join(control_plane.dir, "templates", "handoff.yml"), File.join(target, "handoff.yml"),
                       "PHASE" => phase.output, "SKILL" => skill.name, "PROFILE" => skill.profile.to_s,
                       "NEXT" => next_phase_id(phase))
      end
    end

    # A repository whose profile records a user-facing framework renders
    # something a person perceives or operates, and one whose profile
    # records a published privacy, security, or terms document has made
    # promises a change can break; a new change there starts with the
    # matching surface declared, and the author turns it off with a
    # reason. Done as a text edit so the template's comments survive
    # (YAML.dump would drop them).
    def declare_surfaces!
      path = File.join(dir, "metadata.yml")
      body = File.read(path)
      updated = body
      frameworks = Advisory.ui_frameworks(control_plane)
      unless frameworks.empty?
        updated = updated.sub(/^(\s+accessibility:)\s*false\b.*$/) { "#{Regexp.last_match(1)} true   # set by change new: user-facing framework detected (#{frameworks.join(', ')}); .ai/rules/accessibility.md applies" }
      end
      documents = Advisory.policy_documents(control_plane)
      unless documents.empty?
        updated = updated.sub(/^(\s+policy:)\s*false\b.*$/) { "#{Regexp.last_match(1)} true   # set by change new: published policy document recorded (#{documents.join(', ')}); .ai/rules/policy-conformance.md applies" }
      end
      File.write(path, updated) unless updated == body
    end

    def next_phase_id(phase)
      control_plane.transitions.dig(phase.id, "next") || control_plane.successor(phase)&.id || "done"
    end

    def copy_templates(from, to)
      return unless File.directory?(from)
      Dir.glob("**/*", File::FNM_DOTMATCH, base: from).each do |rel|
        next if [".", ".."].include?(File.basename(rel))
        src = File.join(from, rel)
        dst = File.join(to, rel)
        if File.directory?(src)
          FileUtils.mkdir_p(dst)
        elsif !File.exist?(dst)
          FileUtils.mkdir_p(File.dirname(dst))
          FileUtils.cp(src, dst)
        end
      end
    end

    # Every template is YAML, so a substituted value is emitted as a YAML
    # scalar: plain when that round-trips, quoted otherwise (a title with
    # ": " in it, for instance, would otherwise yield an unreadable file).
    def write_template(src, dst, vars)
      body = File.read(src).gsub(/\$\{([A-Z_]+)\}/) do
        name = Regexp.last_match(1)
        vars.key?(name) ? yaml_scalar(vars[name]) : "${#{name}}"
      end
      File.write(dst, body)
    end

    def yaml_scalar(value)
      return "" if value.nil?
      text = value.to_s
      loaded = YAML.safe_load(text, permitted_classes: [Time, Date])
      plain = (loaded == text || loaded.is_a?(Time) || loaded.is_a?(Date)) && !text.include?("\n") && !text.start_with?("#")
      return text if plain
      YAML.dump(text).sub(/\A--- ?/, "").chomp
    rescue Psych::Exception
      YAML.dump(text).sub(/\A--- ?/, "").chomp
    end

    def load(path)
      YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
    end
  end
end
