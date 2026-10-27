# frozen_string_literal: true

require "yaml"
require "date"
require_relative "display"
require_relative "change_record"
require_relative "advisory"

module SoftFoundry
  # Where a change stands now, from the files the record already holds:
  # metadata.yml and each phase's handoff.yml. It never runs the gate and
  # never writes. Every fact is one line with a stable prefix, and every
  # piece of recorded text goes through Display, so a note cannot forge a
  # line or move the cursor.
  #
  #   change: <slug>
  #   phase: <current phase> (status: ..., risk: ..., track: ...)
  #   phase-status: <phase> <status>      one per lifecycle phase
  #   findings: <phase> <n> (<severity> <n>, ...)   or `findings: none`
  #   blocking: <phase>: <item>; ...                or `blocking: none`
  #   owed: <what>                                  or `owed: none`
  #   note: <why a phase could not be read>
  class ChangeSummary
    # A handoff is a few KB; anything larger is not read.
    MAX_BYTES = 256 * 1024
    SEVERITY_ORDER = %w[blocker critical high major medium minor low].freeze

    Handoff = Data.define(:status, :data, :reason)

    def initialize(record, git:)
      @record = record
      @plane = record.control_plane
      @git = git
    end

    def lines
      meta = read(File.join(@record.dir, "metadata.yml"))
      meta = {} unless meta.is_a?(Hash)
      handoffs = @plane.phases.to_h { |phase| [phase, handoff(phase)] }
      out = ["change: #{Display.safe(@record.slug)}"]
      out << "phase: #{Display.safe(meta['current_phase'])} (status: #{Display.safe(meta['status'])}, risk: #{Display.safe(meta['risk'])}, track: #{Display.safe(meta['track'])})"
      handoffs.each { |phase, h| out << "phase-status: #{phase.id} #{h.status}" }
      handoffs.each { |phase, h| out << "note: #{phase.id} #{Display.safe(h.reason)}" if h.reason }
      out.concat(finding_lines(handoffs))
      out.concat(blocking_lines(handoffs))
      out.concat(owed_lines(meta))
      out
    end

    private

    def handoff(phase)
      path = @record.handoff_path(phase)
      return Handoff.new("missing", nil, nil) unless File.file?(path)
      size = File.size(path)
      return Handoff.new("unreadable", nil, "handoff.yml is #{size} bytes; the summary reads at most #{MAX_BYTES}") if size > MAX_BYTES
      data = read(path)
      return Handoff.new("unreadable", nil, "handoff.yml is not a mapping") unless data.is_a?(Hash)
      Handoff.new(Display.safe(data["status"]), data, nil)
    rescue Psych::Exception => e
      Handoff.new("unreadable", nil, "handoff.yml is not valid YAML without aliases (#{e.message.lines.first.to_s.strip}); redo or repair the file")
    rescue SystemCallError => e
      Handoff.new("unreadable", nil, "handoff.yml could not be read (#{e.class.name.split('::').last})")
    end

    def read(path)
      YAML.safe_load(SoftFoundry.read_text(path), permitted_classes: [Time, Date], aliases: false)
    end

    def finding_lines(handoffs)
      rows = handoffs.filter_map do |phase, h|
        list = h.data && h.data["findings"]
        next unless list.is_a?(Array) && !list.empty?
        counts = list.map { |f| f.is_a?(Hash) ? Display.safe(f["severity"]) : "unspecified" }.tally
        ordered = counts.sort_by { |sev, _| [SEVERITY_ORDER.index(sev) || SEVERITY_ORDER.size, sev] }
        "findings: #{phase.id} #{list.size} (#{ordered.map { |sev, n| "#{sev} #{n}" }.join(', ')})"
      end
      rows.empty? ? ["findings: none"] : rows
    end

    def blocking_lines(handoffs)
      rows = handoffs.filter_map do |phase, h|
        list = h.data && h.data["blocking"]
        "blocking: #{phase.id}: #{Display.list(list)}" if list.is_a?(Array) && !list.empty?
      end
      rows.empty? ? ["blocking: none"] : rows
    end

    def owed_lines(meta)
      rows = []
      rows << "owed: status #{Display.safe(meta['status'])}; a person's decision is recorded under human_decisions in metadata.yml before the change moves on" if meta["status"].to_s == "awaiting_human"
      release = meta["release"]
      items = release.is_a?(Hash) && release["items"].is_a?(Array) ? release["items"].select { |i| i.is_a?(Hash) && !ChangeRecord.discharged?(i) } : []
      items.first(Display::LIMIT).each { |i| rows << "owed: release item #{Display.safe(i['id'])}: #{Display.safe(i['description'])}" }
      rows << "owed: and #{items.size - Display::LIMIT} more release items" if items.size > Display::LIMIT
      rows.concat(advisory_lines)
      rows.empty? ? ["owed: none"] : rows
    end

    def advisory_lines
      notices = Advisory.new(@record, git: @git).notices
      shown = notices.first(Display::LIMIT).map { |n| "owed: advisory #{Display.safe(n.area)}: #{Display.safe(n.message)}" }
      shown << "owed: and #{notices.size - Display::LIMIT} more advisories" if notices.size > Display::LIMIT
      shown
    rescue StandardError => e
      ["note: advisories could not be read (#{Display.safe(e.message.lines.first.to_s.strip)})"]
    end
  end
end
