# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"

module SoftFoundry
  # A durable `changes/<slug>/` record initialized from control-plane templates.
  class ChangeRecord
    STATUSES = %w[pending in_progress complete blocked].freeze

    attr_reader :root, :slug, :control_plane

    def self.create(root, slug, control_plane:, title: nil, branch: nil, worktree: nil, now: Time.now)
      record = new(root, slug, control_plane: control_plane)
      raise "change record already exists: #{record.dir}" if record.exists?
      record.send(:scaffold, title: title || slug, branch: branch || slug, worktree: worktree || root, now: now)
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

    # The commit that represents this change's *finished* work, or nil if
    # it never reached judgment. Deliberately not last_commit_sha: an
    # early phase's commit_sha is just wherever the branch happened to
    # fork from, which is almost always already an ancestor of the
    # default branch - checking that would call every early, abandoned
    # change "merged." Only once judgment (or learning) has completed
    # does "this commit is an ancestor of main" actually mean "this
    # change's work merged," which is what `ci` and `change close` need.
    def commit_sha_at_judgment
      %w[learn judge].each do |id|
        phase = control_plane.phase(id)
        h = phase && handoff(phase)
        return h["commit_sha"] if h && h["status"] == "complete" && h["commit_sha"]
      end
      nil
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

    private

    def scaffold(title:, branch:, worktree:, now:)
      FileUtils.mkdir_p(dir)
      write_template(File.join(control_plane.dir, "templates", "change", "metadata.yml"), File.join(dir, "metadata.yml"),
                     "CHANGE" => slug, "TITLE" => title, "BRANCH" => branch, "WORKTREE" => worktree, "CREATED_AT" => now.utc.iso8601)
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

    def write_template(src, dst, vars)
      body = File.read(src).gsub(/\$\{([A-Z_]+)\}/) { vars.fetch(Regexp.last_match(1)) { "${#{Regexp.last_match(1)}}" } }
      File.write(dst, body)
    end

    def load(path)
      YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
    end
  end
end
