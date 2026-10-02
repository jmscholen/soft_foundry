# frozen_string_literal: true

require "open3"
require "time"
require_relative "git"
require_relative "shell"
require_relative "control_plane"
require_relative "change_index"
require_relative "snapshot"

module SoftFoundry
  # The Soft Foundry processes running on this machine under this user:
  # every `soft-foundry ...` command still alive, in whichever repository
  # and session it was started, with what it is doing and the coding-shell
  # session a phase runner launched. Read from `ps`; nothing is signalled
  # or changed.
  #
  # A command line is whatever a process chose to call itself, and a
  # runner's passthrough flags or a session's prompt are not ours to
  # repeat. Only named fields that pass validation are reported, never
  # the command line.
  class Processes
    COMMANDS = %w[init onboard models doctor check change budget gate ci hooks guard phase learn scan update ui ps shell].freeze
    SUBCOMMANDS = {
      "change" => %w[new status list vet reopen close request-discharge],
      "budget" => %w[status record threshold],
      "hooks" => %w[install uninstall],
      "learn" => %w[list promote],
      "phase" => %w[run]
    }.freeze
    # Commands that act on one change, so the branch names it when the
    # command line does not.
    CHANGE_SCOPED = ["phase run", "gate", "change status", "budget status", "budget record"].freeze
    LINE = /\A\s*(\d+)\s+(\d+)\s+(\w{3}\s+\w{3}\s+\d+\s+[\d:]+\s+\d{4})\s+(.*)\z/
    PHASE = /\A[A-Za-z0-9][A-Za-z0-9_-]{0,39}\z/
    SLUG = %r{\A[A-Za-z0-9][A-Za-z0-9._/-]{0,99}\z}
    NAME = /\A[\w.-]{1,40}\z/

    def initialize(root, ps: nil, cwd: nil)
      @root = File.expand_path(root)
      @ps = ps || method(:run_ps)
      @cwd = cwd || method(:cwd_of)
    end

    # Running processes as plain data, with the runs this repository's
    # records say were started and never finished.
    def snapshot
      list = self.list
      { "version" => Snapshot::VERSION, "generated_at" => Time.now.utc.iso8601, "processes" => list, "recorded_runs" => recorded_runs(list) }
    rescue SystemCallError, IOError => e
      { "version" => Snapshot::VERSION, "generated_at" => Time.now.utc.iso8601, "processes" => [], "recorded_runs" => [],
        "error" => "could not list processes: #{Snapshot.plain(e.message)}" }
    end

    def list
      rows = @ps.call.to_s.scrub("?").lines.filter_map { |line| LINE.match(line.chomp) }
                .map { |m| { pid: m[1].to_i, ppid: m[2].to_i, started: m[3], tokens: m[4].split } }
      rows.filter_map { |row| describe(row, rows) }.sort_by { |p| [p["started_at"].to_s, p["pid"]] }
    end

    private

    def describe(row, rows)
      args = arguments(row[:tokens]) or return nil
      command = command_of(args) or return nil
      args = args.take_while { |a| a != "--" }
      dir = directory(row[:pid])
      here = !dir.nil? && dir == real(@root)
      {
        "pid" => row[:pid],
        "command" => command,
        "phase" => phase_of(command, args),
        "change" => change_of(command, args, dir),
        "shell" => shell_of(command, args),
        "port" => command == "ui" ? option(args, "--port")&.then { |v| v.match?(/\A\d{1,5}\z/) ? v.to_i : nil } : nil,
        "session" => command == "phase run" ? session(row[:pid], rows) : nil,
        "repository" => here ? "." : display(dir),
        "here" => here,
        "self" => row[:pid] == Process.pid,
        "started_at" => started(row[:started])
      }
    end

    # The arguments given to soft-foundry, or nil when the process is not
    # one: the executable itself, or ruby (with its own flags) running it.
    # A process that only mentions soft-foundry somewhere is not one.
    def arguments(tokens)
      index = 0
      if File.basename(tokens.first.to_s).match?(/\Aruby[\d.]*\z/)
        index = 1
        index += %w[-I -r].include?(tokens[index]) ? 2 : 1 while tokens[index]&.start_with?("-")
      end
      File.basename(tokens[index].to_s) == "soft-foundry" ? tokens[(index + 1)..] : nil
    end

    def command_of(args)
      first = args.first
      return nil unless COMMANDS.include?(first)
      sub = args[1]
      SUBCOMMANDS.fetch(first, []).include?(sub) ? "#{first} #{sub}" : first
    end

    def option(args, name)
      index = args.index(name)
      index && args[index + 1]
    end

    def phase_of(command, args)
      value = { "phase run" => args[2], "gate" => args[1] }[command]
      value&.match?(PHASE) ? value : nil
    end

    def change_of(command, args, dir)
      named = option(args, "--change")
      named ||= args[2] if command.start_with?("change ") && command != "change list" && !args[2].to_s.start_with?("-")
      return (named.match?(SLUG) && !named.include?("..") ? named : nil) if named
      CHANGE_SCOPED.include?(command) && dir ? branch_change(dir) : nil
    end

    # The change a repository's checked-out branch belongs to, as the CLI
    # resolves it: the branch name, or the branch without `change/`.
    def branch_change(dir)
      branch = Git.new(dir).branch.to_s
      [branch, branch.sub(%r{\Achange/}, "")].uniq.find do |slug|
        slug.match?(SLUG) && !slug.include?("..") && File.exist?(File.join(dir, "changes", slug, "metadata.yml"))
      end
    rescue SystemCallError
      nil
    end

    def shell_of(command, args)
      case command
      when "phase run" then Shell::COMMANDS.key?(option(args, "--shell")) ? option(args, "--shell") : "claude"
      when "shell" then Shell::COMMANDS.key?(args[1]) ? args[1] : nil
      end
    end

    # The session a phase runner launched: its child process, by name.
    def session(pid, rows)
      child = rows.find { |r| r[:ppid] == pid } or return nil
      name = File.basename(child[:tokens].first.to_s)
      { "pid" => child[:pid], "name" => name.match?(NAME) ? name : "process" }
    end

    def directory(pid)
      dir = @cwd.call(pid)
      dir.nil? || dir.to_s.empty? ? nil : real(dir.to_s)
    rescue SystemCallError
      nil
    end

    def real(path)
      File.realpath(path)
    rescue SystemCallError
      File.expand_path(path)
    end

    # A directory as shown to a person: under the home directory as ~/...
    def display(dir)
      return nil unless dir
      home = real(Dir.home)
      Snapshot.plain(dir == home || dir.start_with?("#{home}/") ? dir.sub(home, "~") : dir)
    end

    # `ps` reports the start in local time, e.g. "Fri Oct  2 00:02:33 2026".
    def started(text)
      Time.strptime(text.squeeze(" "), "%a %b %d %H:%M:%S %Y").utc.iso8601
    rescue ArgumentError
      nil
    end

    # Phases this repository's open records say `phase run` started and
    # did not finish, each matched with the live process if there is one.
    def recorded_runs(list)
      plane = ControlPlane.new(@root)
      return [] unless plane.present?
      index = ChangeIndex.new(@root, plane: plane, git: Git.new(@root))
      index.slugs.flat_map { |slug| runs_in(index, plane, slug, list) }
    rescue StandardError
      []
    end

    def runs_in(index, plane, slug, list)
      record = index.record(slug)
      return [] if record.metadata["status"] == "closed"
      plane.phases.filter_map do |phase|
        by = record.handoff(phase)&.fetch("executed_by", nil)
        next unless by.is_a?(Hash) && by["started_at"] && by["finished_at"].nil?
        live = list.find { |p| p["here"] && p["command"] == "phase run" && p["change"] == slug && plane.phase(p["phase"].to_s) == phase }
        { "change" => slug, "phase" => phase.id, "shell" => Snapshot.plain(by["shell"].to_s), "started_at" => Snapshot.stamp(by["started_at"]),
          "live" => !live.nil?, "pid" => live && live["pid"] }
      end
    rescue StandardError
      []
    end

    def run_ps
      out, status = Open3.capture2({ "LC_ALL" => "C" }, "ps", "x", "-ww", "-o", "pid=", "-o", "ppid=", "-o", "lstart=", "-o", "command=", err: File::NULL)
      raise IOError, "ps exited #{status.exitstatus}" unless status.success?
      out
    end

    # A process's working directory: /proc where there is one, lsof otherwise.
    def cwd_of(pid)
      link = "/proc/#{pid}/cwd"
      return File.readlink(link) if File.symlink?(link)
      out, status = Open3.capture2("lsof", "-a", "-p", pid.to_s, "-d", "cwd", "-Fn", err: File::NULL)
      status.success? ? out.lines.find { |line| line.start_with?("n") }&.then { |line| line[1..].strip } : nil
    rescue SystemCallError
      nil
    end
  end
end
