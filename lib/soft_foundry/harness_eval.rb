# frozen_string_literal: true

require "yaml"
require "json"
require "time"
require "date"
require "tmpdir"
require "fileutils"
require "open3"
require "stringio"
require_relative "text"
require_relative "control_plane"
require_relative "change_record"
require_relative "gate"
require_relative "git"

module SoftFoundry
  # Harness evals: measurements of the control plane itself, kept under
  # .ai/harness-evals/cases/ and run by `soft-foundry eval`. A `gate` case
  # plants a change record (and optionally a code change) in a scratch
  # repository carrying this repository's control plane and asserts which
  # gate check passes or fails; a `live` case plants application files and
  # a record, runs one phase in a fresh coding-shell session through
  # `phase run`, and asserts that the phase's findings name the planted
  # defect. Nothing here writes into .ai/ or any real change record: every
  # case runs in a temporary directory that is removed when it ends.
  #
  # The cases are protected from every skill (HARNESS_EVALS is denied to
  # read and write), so an implementing agent cannot read or tailor them;
  # `eval` prints ids, descriptions, and outcomes, never case content.
  module HarnessEval
    DIR = ".ai/harness-evals/cases"
    TMP_PREFIX = "soft-foundry-eval-"
    KINDS = %w[gate live].freeze
    OUTCOMES = %w[pass fail].freeze
    STATUSES = %w[intake in_progress exploring awaiting_human].freeze
    MAX_FILES = 200
    MAX_FILE_BYTES = 65_536
    FILE_KEYS = [%w[record files], %w[record later_files], %w[repository files], %w[application files]].freeze

    # Tokens a case's file contents may carry. ${COMMIT} is the commit the
    # record's phases were bound to; ${APP_FILE} is a code file in the
    # control plane's APP group; the canaries are secret-shaped strings and
    # an invisible character, built here so that no case file carries one
    # (the control-plane scan would refuse it).
    COMMIT_TOKEN = "${COMMIT}"
    APP_FILE_TOKEN = "${APP_FILE}"
    CANARIES = {
      "${CANARY_AWS}" => "AKIA#{'IOSFODNN7EXAMPLE'}",
      "${CANARY_OPENAI}" => "sk-#{'canary'}#{'0' * 26}",
      "${INVISIBLE_ZWSP}" => [0x200B].pack("U")
    }.freeze

    Case = Data.define(:id, :kind, :description, :phase, :record, :repository, :application, :expect, :path)
    Result = Data.define(:id, :kind, :outcome, :detail, :phase, :check, :expected, :observed, :shell, :model, :matched) do
      def to_h = super.transform_keys(&:to_s)
    end

    class CaseError < StandardError; end

    module_function

    def case_paths(root)
      Dir.glob("#{DIR}/*.yml", base: root).sort.map { |rel| File.join(root, rel) }
    end

    # Loads one case or raises CaseError naming every problem.
    def load_case(path, plane)
      data = YAML.safe_load(SoftFoundry.read_text(path), permitted_classes: [Time, Date], aliases: true)
      problems = problems_in(data, path, plane)
      raise CaseError, problems.join("; ") unless problems.empty?
      Case.new(id: data["id"], kind: data["kind"], description: data["description"].to_s, phase: data["phase"].to_s,
               record: data["record"].is_a?(Hash) ? data["record"] : {}, repository: data["repository"].is_a?(Hash) ? data["repository"] : {},
               application: data["application"].is_a?(Hash) ? data["application"] : {}, expect: data["expect"], path: path)
    rescue Psych::Exception => e
      raise CaseError, "not valid YAML: #{e.message}"
    end

    # What `check` reports: every case file's problems, prefixed by path.
    def lint(root, plane)
      case_paths(root).flat_map do |path|
        rel = path.delete_prefix("#{File.expand_path(root)}/")
        begin
          load_case(path, plane)
          []
        rescue CaseError => e
          ["#{rel}: #{e.message}"]
        end
      end
    end

    # Problems with a case's shape. Structure only, like every lint.
    def problems_in(data, path, plane)
      return ["not a mapping"] unless data.is_a?(Hash)
      problems = []
      base = File.basename(path, ".yml")
      problems << "id '#{data['id']}' must equal the file name '#{base}'" unless data["id"].to_s == base
      problems << "kind '#{data['kind']}' is not one of #{KINDS.join(', ')}" unless KINDS.include?(data["kind"].to_s)
      problems << "description is empty" if data["description"].to_s.strip.empty?
      expect = data["expect"]
      problems << "expect is missing" unless expect.is_a?(Hash)
      record = data["record"]
      problems << "record must be a mapping" unless record.nil? || record.is_a?(Hash)
      if record.is_a?(Hash)
        %w[complete skipped].each do |key|
          Array(record[key]).each { |id| problems << "record.#{key} names '#{id}', which is not a lifecycle phase" unless plane.phase(id.to_s) }
        end
        Hash(record["handoff"]).each do |id, value|
          problems << "record.handoff names '#{id}', which is not a lifecycle phase" unless plane.phase(id.to_s)
          problems << "record.handoff.#{id} must be a mapping" unless value.is_a?(Hash)
        end
        problems << "record.status '#{record['status']}' is not one of #{STATUSES.join(', ')}" if record.key?("status") && !STATUSES.include?(record["status"].to_s)
      end
      count = 0
      FILE_KEYS.each do |outer, inner|
        files = data.dig(outer, inner)
        next if files.nil?
        unless files.is_a?(Hash)
          problems << "#{outer}.#{inner} must be a mapping from path to content"
          next
        end
        files.each do |rel, content|
          count += 1
          problems << "#{outer}.#{inner}: '#{rel}' is not a safe relative path" unless safe_path?(rel)
          problems << "#{outer}.#{inner}: '#{rel}' content must be text" unless content.is_a?(String)
          problems << "#{outer}.#{inner}: '#{rel}' is #{content.bytesize} bytes; a case file holds at most #{MAX_FILE_BYTES} bytes" if content.is_a?(String) && content.bytesize > MAX_FILE_BYTES
        end
      end
      problems << "a case may write at most #{MAX_FILES} files (#{count})" if count > MAX_FILES
      if expect.is_a?(Hash)
        case data["kind"].to_s
        when "gate"
          problems << "expect.phase '#{expect['phase']}' is not a lifecycle phase" unless plane.phase(expect["phase"].to_s)
          problems << "expect.outcome '#{expect['outcome']}' is not one of #{OUTCOMES.join(', ')}" unless OUTCOMES.include?(expect["outcome"].to_s)
          if expect.key?("check") && !Gate::CHECKS.key?(expect["check"].to_s)
            problems << "expect.check '#{expect['check']}' is not a gate check (#{Gate::CHECKS.keys.join(', ')})"
          end
        when "live"
          problems << "phase '#{data['phase']}' is not a lifecycle phase" unless plane.phase(data["phase"].to_s)
          finding = expect["finding"]
          if finding.is_a?(String) && !finding.empty?
            begin
              Regexp.new(finding)
            rescue RegexpError => e
              problems << "expect.finding is not a valid regular expression (#{e.message})"
            end
          else
            problems << "expect.finding (a regular expression) is required for a live case"
          end
        end
      end
      problems
    end

    # Relative, inside the tree, no traversal, no home expansion.
    def safe_path?(rel)
      s = rel.to_s
      return false if s.empty? || s.start_with?("/", "~") || s.include?("\0")
      return false if s.split("/").any? { |part| part == ".." || part.empty? }
      s == APP_FILE_TOKEN || !s.include?("${")
    end

    # Runs cases in scratch repositories built from `root`'s control plane.
    class Runner
      def initialize(root, plane: ControlPlane.new(root))
        @root = File.expand_path(root)
        @plane = plane
      end

      # Every case (or the named ones), each as a Result, yielded as it
      # finishes. `shell_runner` replaces the coding shell for live cases:
      # a callable taking (launch, scratch_root) or (launch) and returning
      # an exit status.
      def run(ids: nil, live: false, shell: nil, extra: [], shell_runner: nil)
        results = []
        loaded = HarnessEval.case_paths(@root).map do |path|
          [File.basename(path, ".yml"), path]
        end
        wanted = ids.nil? || ids.empty? ? loaded.map(&:first) : ids
        wanted.each do |id|
          path = loaded.assoc(id)&.last
          result =
            if path.nil?
              Result.new(id: id, kind: nil, outcome: "error", detail: "no such case under #{DIR}", phase: nil, check: nil, expected: nil, observed: nil, shell: nil, model: nil, matched: [])
            else
              run_path(path, live: live, shell: shell, extra: extra, shell_runner: shell_runner)
            end
          results << result
          yield result if block_given?
        end
        results
      end

      def run_path(path, live:, shell:, extra:, shell_runner:)
        kase = HarnessEval.load_case(path, @plane)
        run_case(kase, live: live, shell: shell, extra: extra, shell_runner: shell_runner)
      rescue CaseError => e
        Result.new(id: File.basename(path, ".yml"), kind: nil, outcome: "error", detail: e.message, phase: nil, check: nil, expected: nil, observed: nil, shell: nil, model: nil, matched: [])
      end

      def run_case(kase, live: false, shell: nil, extra: [], shell_runner: nil)
        # A case about a track this control plane does not declare is not
        # applicable here, not an error: say so and move on.
        track = kase.record["track"]
        if track && !@plane.track(track.to_s)
          return result(kase, "skip", "needs the #{track} track, which the workflow here does not define")
        end
        if kase.kind == "live"
          unless live
            return result(kase, "skip", "live case; run `soft-foundry eval --live --shell claude|codex|grok --case #{kase.id}`")
          end
          return result(kase, "error", "--live needs --shell claude|codex|grok") if shell.to_s.empty?
        end
        Dir.mktmpdir(TMP_PREFIX) do |dir|
          scratch = File.realpath(dir)
          kase.kind == "live" ? run_live(kase, scratch, shell, extra, shell_runner) : run_gate(kase, scratch)
        end
      rescue StandardError => e
        result(kase, "error", "#{e.class}: #{e.message.to_s.lines.first.to_s.strip}")
      end

      private

      def result(kase, outcome, detail, observed: nil, shell: nil, model: nil, matched: [])
        expect = kase.expect.is_a?(Hash) ? kase.expect : {}
        Result.new(id: kase.id, kind: kase.kind, outcome: outcome, detail: detail,
                   phase: kase.kind == "live" ? kase.phase : expect["phase"].to_s, check: expect["check"]&.to_s,
                   expected: kase.kind == "live" ? expect["finding"].to_s : expect["outcome"].to_s,
                   observed: observed, shell: shell, model: model, matched: matched)
      end

      def run_gate(kase, scratch)
        record, = plant(kase, scratch)
        gate = Gate.new(record, git: Git.new(scratch))
        phase = record.control_plane.phase(kase.expect["phase"].to_s)
        evaluation = gate.evaluate(phase)
        expected = kase.expect["outcome"].to_s
        check_name = kase.expect["check"]&.to_s
        observed, note =
          if check_name
            check = evaluation.checks.find { |c| c.name == check_name }
            check ? [check.outcome.to_s, check.detail] : ["absent", "the gate did not run that check (#{evaluation.checks.map(&:name).join(', ')})"]
          else
            [evaluation.failed? ? "fail" : "pass", evaluation.checks.select { |c| c.outcome == :fail }.map { |c| "#{c.name}: #{c.detail}" }.join("; ")]
          end
        what = [phase.id, check_name].compact.join(" ")
        if observed == expected
          result(kase, "pass", "#{what} #{expected}, as expected", observed: observed)
        else
          result(kase, "fail", "expected #{what} #{expected}, observed #{observed}#{note.to_s.empty? ? '' : " (#{note[0, 200]})"}", observed: observed)
        end
      end

      def run_live(kase, scratch, shell, extra, shell_runner)
        record, = plant(kase, scratch)
        slug = record.slug
        runner = shell_runner && ->(launch) { shell_runner.arity == 2 || shell_runner.arity < 0 ? shell_runner.call(launch, scratch) : shell_runner.call(launch) }
        buffer = StringIO.new
        args = ["phase", "run", kase.phase, "--change", slug, "--shell", shell]
        args += ["--", *extra] unless extra.empty?
        code = CLI.new(args, out: buffer, err: buffer, root: scratch, runner: runner).run
        output = buffer.string
        phase = record.control_plane.phase(kase.phase)
        handoff = record.handoff(phase) || {}
        exit_status = handoff.dig("executed_by", "exit_status")
        model = [handoff.dig("resolved_model", "provider"), handoff.dig("resolved_model", "model")].compact.join("/")
        model = nil if model.empty?
        if exit_status && !exit_status.zero?
          return result(kase, "error", "#{shell} exited #{exit_status}", shell: shell, model: model)
        end
        if code != 0 && handoff["status"].to_s != "complete"
          return result(kase, "error", "phase run returned #{code}; #{output.lines.grep(/fail|cannot/).map(&:strip).first(2).join('; ')}", shell: shell, model: model)
        end
        pattern = Regexp.new(kase.expect["finding"].to_s)
        findings = Array(handoff["findings"]).select { |f| f.is_a?(Hash) }
        matched = findings.select { |f| [f["summary"], f["failure"], f["id"]].compact.join("\n").match?(pattern) }.map { |f| f["id"].to_s }
        if matched.empty?
          prose = Dir.glob("*.md", base: record.phase_dir(phase)).any? { |f| SoftFoundry.read_text(File.join(record.phase_dir(phase), f)).match?(pattern) }
          matched = ["(prose)"] if prose
        end
        label = "#{kase.phase} on #{shell}#{model ? " (#{model})" : ''}"
        if matched.empty?
          result(kase, "fail", "#{label} found no finding matching /#{pattern.source}/ (#{findings.size} #{findings.size == 1 ? 'finding' : 'findings'} recorded)", observed: "miss", shell: shell, model: model)
        else
          result(kase, "pass", "#{label} found #{matched.join(', ')} matching /#{pattern.source}/", observed: "found", shell: shell, model: model, matched: matched)
        end
      end

      # Builds the scratch repository and the planted record. Returns the
      # record and the commit its phases were bound to.
      def plant(kase, scratch)
        FileUtils.cp_r(File.join(@root, ".ai"), scratch)
        FileUtils.rm_rf(File.join(scratch, ".ai", "harness-evals"))
        File.write(File.join(scratch, "AGENTS.md"), "# Agent Bootstrap Contract\n\nRead `.ai/README.md` and `.ai/workflow.yml` before making changes.\n")
        app_file = app_file_for(@plane)
        write_file(scratch, app_file, "puts 1\n")
        write_file(scratch, test_file_for(@plane), "require 'minitest/autorun'\n")
        git(scratch, "init", "-q", "-b", "main")
        git(scratch, "config", "user.email", "eval@example.com")
        git(scratch, "config", "user.name", "soft-foundry eval")
        git(scratch, "config", "gc.auto", "0")
        git(scratch, "config", "gc.autoDetach", "false")
        git(scratch, "config", "maintenance.auto", "false")
        git(scratch, "add", "-A")
        git(scratch, "commit", "-q", "-m", "base")
        slug = "eval-#{kase.id}"
        git(scratch, "checkout", "-q", "-b", "change/#{slug}")
        app_files = Hash(kase.application["files"])
        unless app_files.empty?
          app_files.each { |rel, content| write_file(scratch, rel, content, app_file: app_file) }
          git(scratch, "add", "-A")
          git(scratch, "commit", "-q", "-m", "application under test")
        end

        plane = ControlPlane.new(scratch)
        spec = kase.record
        record = ChangeRecord.create(scratch, slug, control_plane: plane, title: kase.description, branch: "change/#{slug}", track: spec["track"] || plane.default_track)
        meta_path = File.join(record.dir, "metadata.yml")
        meta = YAML.safe_load_file(meta_path, permitted_classes: [Time, Date], aliases: true)
        meta["type"] = "feature"
        meta["risk"] = spec.fetch("risk", "low").to_s
        meta["status"] = spec["status"].to_s if spec.key?("status")
        meta["status"] = "in_progress" if meta["status"] == "intake"
        meta["skipped_phases"] = Array(spec["skipped"]).map { |id| { "phase" => id.to_s, "rationale" => "harness eval case #{kase.id}" } }
        File.write(meta_path, YAML.dump(meta))
        git(scratch, "add", "-A")
        git(scratch, "commit", "-q", "-m", "record #{slug}")
        bound = git(scratch, "rev-parse", "HEAD").strip
        tokens = { COMMIT_TOKEN => bound, APP_FILE_TOKEN => app_file }.merge(CANARIES)

        complete = Array(spec["complete"]).map(&:to_s)
        plane.phases.select { |p| complete.include?(p.id) }.each { |p| complete_phase!(record, p, bound) }
        Hash(spec["handoff"]).each do |id, merge|
          phase = plane.phase(id.to_s)
          h = record.handoff(phase) || {}
          File.write(record.handoff_path(phase), YAML.dump(h.merge(substitute(merge, tokens))))
        end
        Hash(spec["files"]).each { |rel, content| write_file(record.dir, rel, substitute(content, tokens), app_file: app_file) }
        unless spec["commit"] == false
          git(scratch, "add", "-A")
          git(scratch, "commit", "-q", "-m", "record #{slug} phases", "--allow-empty")
        end
        Hash(spec["later_files"]).each { |rel, content| write_file(record.dir, rel, substitute(content, tokens), app_file: app_file) }
        repo_files = Hash(kase.repository["files"])
        repo_files.each { |rel, content| write_file(scratch, rel, substitute(content, tokens), app_file: app_file) }
        if kase.repository["commit"] == true && !repo_files.empty?
          git(scratch, "add", "-A")
          git(scratch, "commit", "-q", "-m", "code changed after the evidence")
        end
        [record, bound]
      end

      def complete_phase!(record, phase, sha)
        dir = record.phase_dir(phase)
        Dir.glob("**/*", base: dir).each do |rel|
          path = File.join(dir, rel)
          next unless File.file?(path) && rel != "handoff.yml"
          File.write(path, SoftFoundry.read_text(path).gsub(/\bTBD\b/, "recorded"))
        end
        h = record.handoff(phase) || {}
        h.merge!("status" => "complete", "commit_sha" => sha, "started_at" => "2026-01-01T00:00:00Z", "completed_at" => "2026-01-01T00:00:00Z",
                 "resolved_model" => { "profile" => h.dig("resolved_model", "profile"), "provider" => "harness", "model" => "planted" }, "blocking" => [])
        File.write(record.handoff_path(phase), YAML.dump(h))
      end

      def substitute(value, tokens)
        case value
        when String then tokens.reduce(value) { |text, (token, replacement)| text.gsub(token, replacement) }
        when Hash then value.to_h { |k, v| [substitute(k, tokens), substitute(v, tokens)] }
        when Array then value.map { |v| substitute(v, tokens) }
        else value
        end
      end

      # A path from a case, resolved under `base`, refused if it escapes.
      def write_file(base, rel, content, app_file: nil)
        rel = app_file if rel == APP_FILE_TOKEN && app_file
        raise CaseError, "'#{rel}' is not a safe relative path" unless HarnessEval.safe_path?(rel)
        abs = File.expand_path(rel, base)
        raise CaseError, "'#{rel}' escapes the scratch repository" unless abs.start_with?("#{File.realpath(base)}/")
        FileUtils.mkdir_p(File.dirname(abs))
        File.write(abs, content.to_s)
      end

      # A code file inside the control plane's APP group and a test file
      # inside TESTS, so a planted code change is one the gate watches.
      def app_file_for(plane) = file_in_group(plane, "APP", "lib/**", "eval_app.rb")
      def test_file_for(plane) = file_in_group(plane, "TESTS", "test/**", "eval_app_test.rb")

      def file_in_group(plane, group, fallback, name)
        glob = Array(plane.path_groups[group]).find { |g| g.end_with?("/**") } || fallback
        File.join(glob.delete_suffix("/**"), name)
      end

      def git(dir, *args)
        out, err, status = Open3.capture3({ "GIT_DIR" => nil, "GIT_WORK_TREE" => nil }, "git", "-C", dir, *args)
        raise "git #{args.first} failed: #{err.strip}" unless status.success?
        out
      end
    end
  end
end
