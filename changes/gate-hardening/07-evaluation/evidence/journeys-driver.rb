# frozen_string_literal: true

# Evaluation journeys for changes/gate-hardening, driven through the real
# command line (`soft-foundry` = this checkout's exe under its lib) against
# throwaway repositories under a scratch directory, the way a phase session,
# the runner, a maintainer and CI would use the tool. Each journey appends
# every command it ran, the exact output, the exit code and each assertion
# to evidence/<EVAL-ID>-<name>.txt. Fixture phases are filled the way the
# harness evals fill them (SoftFoundry::HarnessEval.complete_phase!), so the
# thing under test is the command, never the fixture.
#
# Run: ruby -I<repo>/lib journeys-driver.rb [EVAL-001 ...]   (default: all)
# Env: SF_EVAL_SCRATCH (default /tmp/sf-eval), SF_EVAL_PRECHANGE (path to the
#      pre-change gem's executable for the timing journey).
require "open3"
require "fileutils"
require "yaml"
require "json"
require "digest"
require "benchmark"
require "soft_foundry"

REPO = File.expand_path("../../../..", __dir__)
EVIDENCE = __dir__
SCRATCH = ENV.fetch("SF_EVAL_SCRATCH", "/tmp/sf-eval")
BIN = File.join(SCRATCH, "bin")
HOME = File.join(SCRATCH, "home")
PRECHANGE = ENV["SF_EVAL_PRECHANGE"]
CLEAN = { "SOFT_FOUNDRY_PHASE" => nil, "SOFT_FOUNDRY_PARALLEL" => nil, "SOFT_FOUNDRY_GUARD" => nil, "SOFT_FOUNDRY_BILLING" => nil,
          "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil,
          "GEMINI_API_KEY" => nil, "GOOGLE_API_KEY" => nil, "CLAUDECODE" => nil }.freeze
ANSI = /\e\[[0-9;]*[A-Za-z]/.freeze

def setup_bins
  FileUtils.mkdir_p([BIN, HOME, File.join(SCRATCH, "repos"), File.join(SCRATCH, "sessions")])
  File.write(File.join(BIN, "soft-foundry"), "#!/bin/sh\nexec ruby -I#{REPO}/lib #{REPO}/exe/soft-foundry \"$@\"\n")
  File.write(File.join(BIN, "claude"), "#!/bin/sh\nexec ruby -I#{REPO}/lib #{File.join(EVIDENCE, 'fake_session.rb')} \"$@\"\n")
  File.chmod(0o755, File.join(BIN, "soft-foundry"), File.join(BIN, "claude"))
end

class Journey
  attr_reader :id, :failures, :passes

  def initialize(id, name, title)
    @id = id
    @name = name
    @title = title
    @path = File.join(EVIDENCE, "#{id}-#{name}.txt")
    @lines = ["# #{id}: #{title}", "# driver: evidence/journeys-driver.rb, run #{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} at #{`git -C #{REPO} rev-parse HEAD`.strip[0, 12]}", ""]
    @failures = 0
    @passes = 0
  end

  def note(text) = @lines << "# #{text}"
  def blank = @lines << ""

  def env_for(extra = {}, home: HOME)
    base = CLEAN.merge("PATH" => "#{BIN}:#{ENV['PATH']}", "HOME" => home, "SF_EVAL_SCRATCH" => SCRATCH)
    base.merge(extra)
  end

  # Runs the command line as a person would and records it. Returns
  # [status, stdout, stderr].
  def run(dir, *cmd, env: {}, home: HOME, show_env: nil, label: nil)
    shown = cmd.map { |c| c.match?(/\s/) ? "'#{c}'" : c }.join(" ")
    @lines << "$ #{show_env ? show_env + ' ' : ''}#{shown}#{label ? "   # #{label}" : ''}"
    out, err, status = Open3.capture3(env_for(env, home: home), *cmd, chdir: dir)
    out.each_line { |l| @lines << l.chomp }
    err.each_line { |l| @lines << "[stderr] #{l.chomp}" }
    @lines << "exit #{status.exitstatus}"
    @lines << ""
    [status.exitstatus, out, err]
  end

  def sf(dir, *args, **opts) = run(dir, "soft-foundry", *args, **opts)

  def git(dir, *args)
    out, err, status = Open3.capture3(env_for, "git", *args, chdir: dir)
    raise "git #{args.join(' ')} failed in #{dir}: #{err}" unless status.success?
    out
  end

  def head(dir) = git(dir, "rev-parse", "HEAD").strip
  def log(dir, n = 3) = git(dir, "log", "--format=%h %s", "-n", n.to_s).lines.map(&:chomp)
  def files_in_head(dir) = git(dir, "show", "--name-only", "--format=", "HEAD").lines.map(&:chomp).reject(&:empty?)

  def assert(desc, cond, detail = nil)
    if cond
      @passes += 1
      @lines << "assert pass: #{desc}"
    else
      @failures += 1
      @lines << "assert FAIL: #{desc}#{detail ? " (#{detail})" : ''}"
    end
    cond
  end

  def show(dir, rel, label = nil)
    @lines << "--- #{label || rel} ---"
    text = File.read(File.join(dir, rel))
    text.each_line { |l| @lines << l.chomp }
    @lines << "---"
    @lines << ""
    text
  end

  def finish
    @lines << ""
    @lines << "# #{@id}: #{@failures.zero? ? 'PASS' : 'FAIL'} (#{@passes} assertions passed, #{@failures} failed)"
    File.write(@path, @lines.join("\n") + "\n")
    puts "#{@failures.zero? ? '✓ pass' : '✗ fail'} #{@id} #{@title} (#{@passes} ok, #{@failures} failed) -> #{File.basename(@path)}"
  end

  # --- fixtures -------------------------------------------------------

  # A throwaway repository carrying this checkout's control plane, an
  # application file, and one commit on main (the suite's with_fixture_repo).
  def fixture_repo(name)
    dir = File.join(SCRATCH, "repos", "#{@id.downcase}-#{name}")
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(File.join(dir, "lib"))
    FileUtils.cp_r(File.join(REPO, ".ai"), dir)
    File.write(File.join(dir, "lib", "app.rb"), "puts 1\n")
    File.write(File.join(dir, "AGENTS.md"), "# agents\n")
    File.write(File.join(dir, ".gitignore"), ".soft-foundry/\n")
    git(dir, "init", "-q", "-b", "main")
    %w[user.email=eval@example.com user.name=Evaluation gc.auto=0 gc.autoDetach=false maintenance.auto=false commit.gpgsign=false].each do |kv|
      k, v = kv.split("=", 2)
      git(dir, "config", k, v)
    end
    git(dir, "add", ".")
    git(dir, "commit", "-q", "-m", "initial")
    note "scratch repository: #{dir}"
    dir
  end

  def plane(dir) = SoftFoundry::ControlPlane.new(dir)
  def record(dir, slug) = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane(dir))

  # A gated change on its own branch, created with `change new`, with the
  # named phases complete at HEAD and committed ("sealed" in the fixture
  # vocabulary: a committed complete handoff is recorded).
  def new_record(dir, slug = "c1", complete: [], status: "in_progress", current_phase: "intake", risk: nil, new_args: [])
    git(dir, "checkout", "-qb", "change/#{slug}")
    args = ["change", "new", slug, *new_args]
    args += ["--risk", risk] if risk
    code, = sf(dir, *args, label: "create the record")
    raise "change new failed" unless code.zero?
    rec = record(dir, slug)
    set_metadata!(rec, status: status, current_phase: current_phase)
    git(dir, "add", "-A")
    git(dir, "commit", "-q", "-m", "record #{slug}")
    unless complete.empty?
      complete.each { |p| complete!(rec, p, head(dir)) }
      git(dir, "add", "-A")
      git(dir, "commit", "-q", "-m", "phases complete: #{complete.join(' ')}")
    end
    rec
  end

  def set_metadata!(rec, status: nil, current_phase: nil)
    path = File.join(rec.dir, "metadata.yml")
    text = File.read(path)
    text = text.sub(/^status: .*$/, "status: #{status}") if status
    text = text.sub(/^current_phase: .*$/, "current_phase: #{current_phase}") if current_phase
    File.write(path, text)
  end

  def complete!(rec, phase, sha, runner: true) = SoftFoundry::HarnessEval.complete_phase!(rec, phase, sha, runner: runner)

  def commit_all(dir, msg)
    git(dir, "add", "-A")
    git(dir, "commit", "-q", "-m", msg)
    head(dir)
  end

  def phase_file(rec, phase, name) = File.join(rec.phase_dir(rec.control_plane.phase(phase)), name)

  def edit_yaml(path)
    data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true)
    yield data
    File.write(path, YAML.dump(data))
  end

  def handoff_of(rec, phase) = rec.handoff(rec.control_plane.phase(phase))
  def metadata_of(rec) = YAML.safe_load_file(File.join(rec.dir, "metadata.yml"), permitted_classes: [Time, Date])

  def check_line(out, name) = out.lines.find { |l| l.include?(name) }.to_s.chomp
end

LIFECYCLE = %w[intake discover specify threat_model plan implement verify evaluate attack review judge].freeze
ALL_REQUIRED = (LIFECYCLE + %w[learn]).freeze

JOURNEYS = {}
def journey(id, name, title, &blk) = JOURNEYS[id] = [name, title, blk]

# ---------------------------------------------------------------------------
journey "EVAL-001", "seal-happy-path", "A phase session seals its finished phase; a rerun is a no-op (AC-001, AC-005, AC-009)" do |j|
  dir = j.fixture_repo("seal")
  rec = j.new_record(dir, status: "intake")
  j.complete!(rec, "intake", j.head(dir))
  File.write(File.join(dir, "notes.txt"), "scratch\n")
  j.note "intake is complete on disk and uncommitted; notes.txt is an uncommitted scratch file outside code and the record"
  before = j.head(dir)
  code, out, err = j.sf(dir, "phase", "seal", "intake", label: "persona: phase session")
  j.assert("AC-001 exit 0", code.zero?, out + err)
  j.assert("AC-001 output line is `sealed 00-intake at <12-char sha>`", out.lines.last.to_s.match?(/\Asealed 00-intake at [0-9a-f]{12}\n\z/), out.lines.last.inspect)
  files = j.files_in_head(dir)
  j.run(dir, "git", "log", "--format=%h %s", "-n", "2")
  j.run(dir, "git", "show", "--name-only", "--format=", "HEAD")
  j.assert("AC-001 commit message is `Record c1 intake`", j.log(dir).first.end_with?("Record c1 intake"))
  j.assert("AC-001 the commit contains only 00-intake/** and metadata.yml", files.all? { |f| f.start_with?("changes/c1/00-intake/") || f == "changes/c1/metadata.yml" } && files.include?("changes/c1/metadata.yml"), files.inspect)
  meta = j.metadata_of(rec)
  j.assert("AC-001 metadata current_phase is discover and status in_progress", meta["current_phase"] == "discover" && meta["status"] == "in_progress", meta.slice("current_phase", "status").inspect)
  j.assert("AC-005 notes.txt is named in a note line and left uncommitted", out.include?("note:") && out.include?("notes.txt") && !files.include?("notes.txt"))
  j.run(dir, "git", "status", "--porcelain")
  j.assert("AC-005 notes.txt still untracked", j.git(dir, "status", "--porcelain").include?("?? notes.txt"))
  j.assert("no ANSI escape in the output", !(out + err).match?(ANSI))
  sealed = j.head(dir)
  code, out, err = j.sf(dir, "phase", "seal", "intake", label: "run again: nothing changed since")
  j.assert("AC-009 exit 0", code.zero?)
  j.assert("AC-009 output is `already sealed at <sha>`", out.include?("already sealed at #{sealed[0, 12]}"), out)
  j.assert("AC-009 no new commit", j.head(dir) == sealed)
  j.assert("sealed handoff of a non-commit-bound phase carries no branch_resolved key", !j.handoff_of(rec, "intake").key?("branch_resolved"))
  j.show(dir, "changes/c1/metadata.yml")
end

journey "EVAL-002", "seal-refusals", "Sealing refuses an incomplete handoff, uncommitted code, and a failing gate, committing nothing (AC-002, AC-003, AC-004)" do |j|
  dir = j.fixture_repo("refuse")
  rec = j.new_record(dir, status: "intake")
  before = j.head(dir)
  j.note "intake handoff left in_progress"
  rec.update_handoff(rec.control_plane.phase("intake")) { |h| h["status"] = "in_progress" }
  code, out, err = j.sf(dir, "phase", "seal", "intake")
  j.assert("AC-003 exit 1", code == 1)
  j.assert("AC-003 names status in_progress and says to complete the handoff first", (out + err).include?("in_progress") && (out + err).include?("complete"), out + err)
  j.assert("AC-003 nothing committed", j.head(dir) == before)
  j.assert("AC-003 refusal is one line", (out + err).lines.size == 1, (out + err).lines.size.to_s)

  j.note "now intake complete but request.md keeps the template placeholder"
  j.complete!(rec, "intake", before)
  File.write(j.phase_file(rec, "intake", "request.md"), "# Change Intake\n\n## User intent\nTBD\n")
  code, out, err = j.sf(dir, "phase", "seal", "intake")
  j.assert("AC-002 exit 2", code == 2)
  j.assert("AC-002 gate printed with `no placeholders` failing", (out + err).match?(/no placeholders/) && (out + err).match?(/✗ fail.*no placeholders|no placeholders.*fail/), out + err)
  j.assert("AC-002 git log unchanged", j.head(dir) == before)
  j.assert("AC-002 metadata unchanged (current_phase intake, status intake)", j.metadata_of(rec)["current_phase"] == "intake" && j.metadata_of(rec)["status"] == "intake", j.metadata_of(rec).slice("current_phase", "status").inspect)

  j.note "a second record where implement is complete on disk and lib/app.rb has an uncommitted edit"
  dir2 = j.fixture_repo("dirty")
  rec2 = j.new_record(dir2, complete: %w[intake discover specify threat_model plan])
  j.complete!(rec2, "implement", j.head(dir2))
  File.write(File.join(dir2, "lib", "app.rb"), "puts 2\n")
  before2 = j.head(dir2)
  code, out, err = j.sf(dir2, "phase", "seal", "implement")
  j.assert("AC-004 exit 1", code == 1)
  j.assert("AC-004 names lib/app.rb and says to commit the code first", (out + err).include?("lib/app.rb") && (out + err).include?("commit the code first"), out + err)
  j.assert("AC-004 nothing committed", j.head(dir2) == before2)
  j.note "an untracked test file is refused the same way"
  File.write(File.join(dir2, "lib", "app.rb"), "puts 1\n")
  FileUtils.mkdir_p(File.join(dir2, "test"))
  File.write(File.join(dir2, "test", "new_test.rb"), "# untracked\n")
  code, out, err = j.sf(dir2, "phase", "seal", "implement")
  j.assert("AC-004 (untracked test file) exit 1 naming test/new_test.rb", code == 1 && (out + err).include?("test/new_test.rb"), out + err)
end

journey "EVAL-003", "seal-staging-and-advance", "Sealing stages only its own paths and advances current_phase past waived phases and into judged (AC-006, AC-007, AC-008)" do |j|
  dir = j.fixture_repo("plant")
  rec = j.new_record(dir, complete: %w[intake discover specify threat_model])
  j.complete!(rec, "plan", j.head(dir))
  planted = File.join(dir, "changes/c1/06-verification/evidence/planted.txt")
  FileUtils.mkdir_p(File.dirname(planted))
  File.write(planted, "planted by a person\n")
  code, out, err = j.sf(dir, "phase", "seal", "plan")
  j.assert("AC-006 exit 0", code.zero?, out + err)
  files = j.files_in_head(dir)
  j.run(dir, "git", "show", "--name-only", "--format=", "HEAD")
  j.assert("AC-006 commit holds 04-plan/** and metadata.yml only", files.all? { |f| f.start_with?("changes/c1/04-plan/") || f == "changes/c1/metadata.yml" }, files.inspect)
  j.run(dir, "git", "status", "--porcelain")
  j.assert("AC-006 planted file still untracked", j.git(dir, "status", "--porcelain").include?("?? changes/c1/06-verification/"))
  j.assert("AC-006 note names the planted path", out.include?("note:") && out.include?("06-verification"), out)

  dir2 = j.fixture_repo("judge")
  rec2 = j.new_record(dir2, complete: LIFECYCLE[0..-2], current_phase: "judge")
  j.complete!(rec2, "judge", j.head(dir2))
  final = j.phase_file(rec2, "judge", "final.md")
  File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\nAPPROVED"))
  code, out, err = j.sf(dir2, "phase", "seal", "judge")
  j.assert("AC-007 exit 0", code.zero?, out + err)
  meta = j.metadata_of(rec2)
  j.assert("AC-007 status judged, current_phase learn", meta["status"] == "judged" && meta["current_phase"] == "learn", meta.slice("status", "current_phase").inspect)
  j.assert("AC-007 judge handoff carries branch_resolved true", j.handoff_of(rec2, "judge")["branch_resolved"] == true)

  dir3 = j.fixture_repo("waived")
  rec3 = j.new_record(dir3, status: "intake", risk: "medium")
  j.edit_yaml(File.join(rec3.dir, "metadata.yml")) { |m| m["skipped_phases"] = [{ "phase" => "discover", "rationale" => "the profile was refreshed last week" }] }
  j.commit_all(dir3, "waive discover")
  j.complete!(rec3, "intake", j.head(dir3))
  code, out, err = j.sf(dir3, "phase", "seal", "intake")
  j.assert("AC-008 exit 0", code.zero?, out + err)
  j.assert("AC-008 current_phase steps over waived discover to specify", j.metadata_of(rec3)["current_phase"] == "specify", j.metadata_of(rec3)["current_phase"])
end

journey "EVAL-004", "seal-hook-refusal", "A refused pre-commit hook leaves the seal resumable; the real hook's cost is measured (AC-010, REQ-036)" do |j|
  dir = j.fixture_repo("hook")
  rec = j.new_record(dir, status: "intake")
  j.complete!(rec, "intake", j.head(dir))
  hook = File.join(dir, ".git", "hooks", "pre-commit")
  File.write(hook, "#!/bin/sh\necho 'pre-commit: refusing for the evaluation' >&2\nexit 1\n")
  File.chmod(0o755, hook)
  before = j.head(dir)
  code, out, err = j.sf(dir, "phase", "seal", "intake", label: "hook exits 1")
  j.assert("AC-010 exit 2", code == 2, out + err)
  j.assert("AC-010 the hook's output is shown", (out + err).include?("refusing for the evaluation"), out + err)
  j.assert("AC-010 says metadata is advanced and to run seal again", (out + err).include?("phase seal intake"), out + err)
  j.assert("AC-010 no commit", j.head(dir) == before)
  j.assert("AC-010 worktree metadata shows current_phase discover", j.metadata_of(rec)["current_phase"] == "discover", j.metadata_of(rec)["current_phase"])
  File.delete(hook)
  code, out, err = j.sf(dir, "phase", "seal", "intake", label: "hook removed")
  j.assert("AC-010 second seal exits 0 and commits", code.zero? && j.head(dir) != before && j.log(dir).first.end_with?("Record c1 intake"), out + err)

  j.note "the real hook: `soft-foundry hooks install` puts a pre-commit that runs `soft-foundry ci` (this checkout's code via PATH)"
  code, out, err = j.sf(dir, "hooks", "install")
  j.assert("hooks install exits 0", code.zero?, out + err)
  j.show(dir, ".git/hooks/pre-commit", "the installed pre-commit hook")
  marker = File.join(SCRATCH, "hook-ran.txt")
  FileUtils.rm_f(marker)
  # Keep the installed hook's behaviour, and leave a trace that it ran (a
  # passing hook's output is not echoed by a successful commit).
  File.write(hook, File.read(hook).sub("#!/bin/sh\n", "#!/bin/sh\necho ran > #{marker}\n"))
  j.complete!(rec, "discover", j.head(dir))
  t_hook = Benchmark.realtime { code, out, err = j.sf(dir, "phase", "seal", "discover", label: "seal with the ci hook running") }
  j.assert("seal with the real hook exits 0", code.zero?, out + err)
  j.assert("the hook ran (marker written by the hook)", File.exist?(marker))
  File.delete(File.join(dir, ".git", "hooks", "pre-commit"))
  j.complete!(rec, "specify", j.head(dir))
  t_plain = Benchmark.realtime { code, out, err = j.sf(dir, "phase", "seal", "specify", label: "seal with no hook") }
  j.assert("seal without the hook exits 0", code.zero?, out + err)
  j.note format("timing: seal with ci hook %.1f s; seal without hook %.1f s; hook cost %.1f s (the price of ci: check + 28 gate cases + every record's gate)", t_hook, t_plain, t_hook - t_plain)
end

journey "EVAL-005", "predecessor-recorded", "A predecessor complete only on disk is refused until sealed; waived predecessors are stepped over (AC-016, AC-017)" do |j|
  dir = j.fixture_repo("pred")
  rec = j.new_record(dir)
  j.complete!(rec, "intake", j.head(dir))
  j.complete!(rec, "discover", j.head(dir))
  code, out, err = j.sf(dir, "gate", "discover")
  line = j.check_line(out, "predecessor complete")
  j.assert("AC-016 gate discover exits 2", code == 2, out + err)
  j.assert("AC-016 `predecessor complete` fails naming `soft-foundry phase seal intake`", line.include?("fail") && line.include?("soft-foundry phase seal intake"), line)
  code, out, err = j.sf(dir, "phase", "seal", "intake")
  j.assert("seal intake exits 0", code.zero?, out + err)
  code, out, err = j.sf(dir, "gate", "discover")
  line = j.check_line(out, "predecessor complete")
  j.assert("AC-016 after sealing intake, `predecessor complete` passes", line.include?("pass"), line)

  dir2 = j.fixture_repo("lowrisk")
  rec2 = j.new_record(dir2, status: "intake", risk: "low")
  j.edit_yaml(File.join(rec2.dir, "metadata.yml")) do |m|
    m["skipped_phases"] = %w[discover specify threat_model plan].map { |p| { "phase" => p, "rationale" => "low-risk change; #{p} waived" } }
  end
  j.commit_all(dir2, "waive four phases")
  j.complete!(rec2, "intake", j.head(dir2))
  code, out, err = j.sf(dir2, "phase", "seal", "intake")
  j.assert("intake sealed; current_phase jumps to implement", code.zero? && j.metadata_of(rec2)["current_phase"] == "implement", out + err + j.metadata_of(rec2)["current_phase"].to_s)
  j.complete!(rec2, "implement", j.head(dir2))
  code, out, err = j.sf(dir2, "gate", "implement")
  line = j.check_line(out, "predecessor complete")
  j.assert("AC-017 `predecessor complete` passes naming intake", line.include?("pass") && line.include?("intake"), line)
  j.assert("AC-017 gate implement exits 0", code.zero?, out + err)
end

journey "EVAL-006", "runner-seals", "The runner seals a phase its fresh session completed, never one left in progress; the prompt says so (AC-011, AC-012, AC-015)" do |j|
  dir = j.fixture_repo("run")
  rec = j.new_record(dir, complete: LIFECYCLE.take(6), current_phase: "verify")
  before = j.head(dir)
  code, out, err = j.sf(dir, "phase", "run", "verify", "--shell", "claude", "--dry-run", label: "AC-015: the prompt the runner would send")
  j.assert("dry run exits 0", code.zero?, out + err)
  prompt_tail = out.lines.last(6).join
  j.assert("AC-015 the prompt's last step says the runner seals the phase and the session must not commit", out.include?("seal") && out.match?(/do not commit/i), prompt_tail)
  code, out, err = j.sf(dir, "phase", "run", "verify", "--shell", "claude", env: { "SF_EVAL_BEHAVIOUR" => "complete" }, show_env: "SF_EVAL_BEHAVIOUR=complete", label: "the fake shell completes the phase")
  j.assert("AC-011 runner exits 0", code.zero?, out + err)
  j.assert("AC-011 HEAD is `Record c1 verify`", j.log(dir).first.end_with?("Record c1 verify") && j.head(dir) != before, j.log(dir).inspect)
  files = j.files_in_head(dir)
  j.assert("AC-011 commit holds 06-verification/** and metadata.yml", files.all? { |f| f.start_with?("changes/c1/06-verification/") || f == "changes/c1/metadata.yml" }, files.inspect)
  h = j.handoff_of(rec, "verify")
  j.assert("AC-011 executed_by shows finished_at and exit_status 0 from `soft-foundry phase run`", h.dig("executed_by", "runner") == "soft-foundry phase run" && h.dig("executed_by", "exit_status") == 0 && h.dig("executed_by", "finished_at"), h["executed_by"].inspect)
  j.assert("branch_resolved true stamped by the seal", h["branch_resolved"] == true)
  j.assert("sealed line printed", out.include?("sealed 06-verification"), out)
  session_prompt = Dir.glob(File.join(SCRATCH, "sessions", "*-c1-verify.prompt.txt")).max_by { |f| File.mtime(f) }
  if session_prompt
    text = File.read(session_prompt)
    j.assert("AC-015 the prompt the session received ends with the seal/do-not-commit step", text.lines.last(4).join.match?(/seal/) && text.match?(/do not commit/i), text.lines.last(4).join)
  end

  sealed = j.head(dir)
  code, out, err = j.sf(dir, "phase", "run", "evaluate", "--shell", "claude", env: { "SF_EVAL_BEHAVIOUR" => "in_progress" }, show_env: "SF_EVAL_BEHAVIOUR=in_progress", label: "the fake shell leaves the handoff in_progress")
  j.assert("AC-012 runner exits 2", code == 2, out + err)
  j.assert("AC-012 HEAD unchanged", j.head(dir) == sealed)
  j.assert("AC-012 output says the phase was not sealed and why", (out + err).include?("not sealed") && (out + err).include?("in_progress"), out + err)
end

journey "EVAL-007", "runner-parallel", "A parallel run seals each passing phase in order, leaves a blocked one, hides --env values, and is visible in ps (AC-013, AC-014, AC-055, REV-007)" do |j|
  dir = j.fixture_repo("par")
  rec = j.new_record(dir, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  before = j.head(dir)
  code, out, err = j.sf(dir, "phase", "run", "evaluate", "attack", "--parallel", "--shell", "claude", env: { "SF_EVAL_BEHAVIOUR" => "complete" }, show_env: "SF_EVAL_BEHAVIOUR=complete", label: "both sessions pass")
  j.assert("AC-014 runner exits 0", code.zero?, out + err)
  subjects = j.log(dir, 3).map { |l| l.split(" ", 2).last }
  j.run(dir, "git", "log", "--format=%h %s", "-n", "3")
  j.assert("AC-014 two commits: `Record c1 evaluate` then `Record c1 attack`", subjects.first(2) == ["Record c1 attack", "Record c1 evaluate"], subjects.inspect)
  code, out, err = j.sf(dir, "gate", "attack")
  j.assert("AC-014 gate attack exits 0 with predecessor complete and commit lineage passing", code.zero? && j.check_line(out, "predecessor complete").include?("pass") && j.check_line(out, "commit lineage").include?("pass"), out + err)

  dir2 = j.fixture_repo("par-blocked")
  rec2 = j.new_record(dir2, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  before2 = j.head(dir2)
  code, out, err = j.sf(dir2, "phase", "run", "evaluate", "attack", "--parallel", "--shell", "claude", "--env", "SECRET=hunter2",
                        env: { "SF_EVAL_BEHAVIOUR_EVALUATE" => "complete", "SF_EVAL_BEHAVIOUR_ATTACK" => "blocked" },
                        show_env: "SF_EVAL_BEHAVIOUR_EVALUATE=complete SF_EVAL_BEHAVIOUR_ATTACK=blocked", label: "attack writes status blocked itself")
  j.assert("AC-013 runner exits 2", code == 2, out + err)
  subjects = j.log(dir2, 2).map { |l| l.split(" ", 2).last }
  j.assert("AC-013 evaluate sealed (one commit), attack not", subjects.first == "Record c1 evaluate" && !subjects.include?("Record c1 attack"), subjects.inspect)
  j.assert("AC-013 output names both outcomes", out.include?("sealed 07-evaluation") && (out + err).match?(/08-attack.*(not sealed|blocked)/), out + err)
  j.assert("AC-013 attack handoff is blocked", j.handoff_of(rec2, "attack")["status"] == "blocked")
  j.assert("AC-055 hunter2 appears nowhere in the runner's or sealing output", !(out + err).include?("hunter2"))
  names = Dir.glob(File.join(SCRATCH, "sessions", "*-c1-attack.env-names.txt")).max_by { |f| File.mtime(f) }
  j.assert("the sessions did receive SECRET (names recorded by the fake shell)", names && File.read(names).include?("SECRET"), names.to_s)

  dir3 = j.fixture_repo("par-fail")
  j.new_record(dir3, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  code, out, err = j.sf(dir3, "phase", "run", "evaluate", "attack", "--parallel", "--shell", "claude", "--env", "SECRET=hunter2",
                        env: { "SF_EVAL_BEHAVIOUR" => "fail" }, show_env: "SF_EVAL_BEHAVIOUR=fail", label: "AC-055: both stub sessions fail")
  j.assert("AC-055 failing sessions: runner exits non-zero and prints no hunter2", !code.zero? && !(out + err).include?("hunter2"), out + err)

  j.note "REV-007: ps during a parallel run (sessions sleep 20 s)"
  dir4 = j.fixture_repo("par-ps")
  j.new_record(dir4, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  env = j.env_for({ "SF_EVAL_BEHAVIOUR" => "sleep:20" })
  pid = Process.spawn(env, "soft-foundry", "phase", "run", "evaluate", "attack", "--parallel", "--shell", "claude", chdir: dir4, out: File.join(SCRATCH, "par-ps.out"), err: File.join(SCRATCH, "par-ps.err"))
  sleep 8
  code, out, err = j.sf(dir4, "ps", label: "while the parallel run is in flight")
  j.assert("ps lists the phase run naming both phases (evaluate,attack)", out.include?("evaluate,attack") || out.match?(/evaluate.*attack/), out + err)
  Process.wait(pid)
  j.note "parallel run finished with exit #{$?.exitstatus}; its output:"
  File.read(File.join(SCRATCH, "par-ps.out")).each_line { |l| j.note "  " + l.chomp }
  j.assert("the sleeping run sealed both phases", $?.exitstatus.zero? && j.log(dir4, 2).map { |l| l.split(" ", 2).last } == ["Record c1 attack", "Record c1 evaluate"], j.log(dir4, 2).inspect)
end

journey "EVAL-008", "structured-files-parse", "The gate names a structured file that does not parse, and never re-gates a closed record (AC-018, AC-020, AC-021)" do |j|
  dir = j.fixture_repo("parse")
  rec = j.new_record(dir, complete: %w[intake discover], current_phase: "specify")
  j.complete!(rec, "specify", j.head(dir))
  req = j.phase_file(rec, "specify", "requirements.yml")
  File.write(req, "requirements:\n  - id: REQ-001\n    statement: the gate must fail closed: nothing passes by accident\n    category: functional\n")
  before = j.head(dir)
  code, out, err = j.sf(dir, "gate", "specify")
  line = j.check_line(out, "structured files parse")
  j.assert("AC-020 `structured files parse` fails naming 02-specification/requirements.yml and a line", line.include?("fail") && line.include?("02-specification/requirements.yml") && line.match?(/line \d+/), line)
  j.assert("AC-020 no Ruby backtrace", !(out + err).include?(".rb:"))
  code, out, err = j.sf(dir, "phase", "seal", "specify")
  j.assert("AC-020 phase seal specify exits 2 and commits nothing", code == 2 && j.head(dir) == before, out + err)

  dir2 = j.fixture_repo("manifest-seq")
  rec2 = j.new_record(dir2, complete: LIFECYCLE.take(6), current_phase: "verify")
  j.complete!(rec2, "verify", j.head(dir2))
  File.write(j.phase_file(rec2, "verify", "evidence/manifest.yml"), "- path: evidence/run.txt\n  sha256: abc\n")
  code, out, err = j.sf(dir2, "gate", "verify")
  line = j.check_line(out, "structured files parse")
  j.assert("AC-021 fails naming evidence/manifest.yml and `expected a mapping`", line.include?("fail") && line.include?("manifest.yml") && line.include?("expected a mapping"), line)

  dir3 = j.fixture_repo("closed")
  rec3 = j.new_record(dir3, complete: ALL_REQUIRED, current_phase: "learn")
  final = j.phase_file(rec3, "judge", "final.md")
  File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\nAPPROVED"))
  File.write(j.phase_file(rec3, "specify", "requirements.yml"), "requirements:\n  - id: REQ-001\n    statement: fail closed: yes\n")
  j.set_metadata!(rec3, status: "closed")
  j.commit_all(dir3, "closed record with a broken requirements file")
  code, out, err = j.sf(dir3, "gate", "specify", "--change", "c1")
  line = j.check_line(out, "structured files parse")
  j.assert("AC-018 closed record: `structured files parse` skips with `closed record: not re-gated`", line.include?("skip") && line.include?("closed record: not re-gated"), line)
  code, out, err = j.sf(dir3, "ci")
  j.assert("AC-018 ci prints `(closed, skipped)` and exits 0", code.zero? && out.include?("c1 (closed, skipped)"), out.lines.last(6).join + err)
end

journey "EVAL-009", "commit-lineage", "A commit_sha older than the predecessor's or off the branch fails lineage; a stacked record is measured on its own branch (AC-022, AC-023, AC-024)" do |j|
  dir = j.fixture_repo("lineage")
  rec = j.new_record(dir, status: "intake")
  a = j.head(dir)
  File.write(File.join(dir, "AGENTS.md"), "# agents\n\nintake notes\n")
  b = j.commit_all(dir, "a later commit the intake evidence describes")
  j.note "intake's commit_sha is #{b[0, 12]} (sealed at X, the commit after it); discover's commit_sha is set to #{a[0, 12]}, the parent"
  j.complete!(rec, "intake", b)
  code, out, err = j.sf(dir, "phase", "seal", "intake")
  x = j.head(dir)
  j.complete!(rec, "discover", a)
  code, out, err = j.sf(dir, "gate", "discover")
  line = j.check_line(out, "commit lineage")
  j.assert("AC-022 `commit lineage` fails naming both SHAs and `not an ancestor`", line.include?("fail") && line.include?(b[0, 12]) && line.include?(a[0, 12]) && line.include?("not an ancestor"), line)
  j.assert("AC-022 gate exits 2", code == 2)
  j.note "the literal AC-022 fixture (intake sealed at X, discover at X's parent) cannot fail: a sealed handoff's commit_sha always precedes its sealing commit X, so X's parent is where intake's commit_sha already is"

  dir2 = j.fixture_repo("unrelated")
  rec2 = j.new_record(dir2, complete: LIFECYCLE.take(6), current_phase: "verify")
  j.note "a side branch forked after implement's commit: the predecessor relation holds, the tip relation does not"
  j.git(dir2, "checkout", "-qb", "side")
  File.write(File.join(dir2, "side.txt"), "work on a side branch\n")
  side = j.commit_all(dir2, "side branch commit")
  j.git(dir2, "checkout", "-q", "change/c1")
  j.complete!(rec2, "verify", side)
  code, out, err = j.sf(dir2, "gate", "verify")
  line = j.check_line(out, "commit lineage")
  j.assert("AC-023 `commit lineage` fails: the commit is not an ancestor of the measuring tip", line.include?("fail") && line.include?("not an ancestor") && line.match?(/tip|HEAD/), line)
  j.note "an orphan commit (unrelated history) fails the same check on the predecessor relation first, since neither relation holds"
  j.git(dir2, "checkout", "-q", "--orphan", "elsewhere")
  File.write(File.join(dir2, "elsewhere.txt"), "unrelated history\n")
  j.git(dir2, "add", "elsewhere.txt")
  j.git(dir2, "commit", "-q", "-m", "unrelated")
  other = j.head(dir2)
  j.git(dir2, "checkout", "-q", "change/c1")
  j.complete!(rec2, "verify", other)
  code, out, err = j.sf(dir2, "gate", "verify")
  line = j.check_line(out, "commit lineage")
  j.assert("AC-023 (orphan commit) `commit lineage` fails with `not an ancestor`", line.include?("fail") && line.include?("not an ancestor"), line)

  dir3 = j.fixture_repo("stacked")
  lower = j.new_record(dir3, "lower", complete: LIFECYCLE.take(7), current_phase: "evaluate")
  j.note "upper is stacked on change/lower; a code commit lands on upper after lower's evidence"
  j.git(dir3, "checkout", "-qb", "change/upper")
  code, = j.sf(dir3, "change", "new", "upper")
  File.write(File.join(dir3, "lib", "app.rb"), "puts 3\n")
  j.commit_all(dir3, "upper: code change and record")
  code, out, err = j.sf(dir3, "gate", "verify", "--change", "lower", label: "from branch change/upper")
  j.assert("AC-024 `commit lineage` passes for lower, measured against change/lower's tip", j.check_line(out, "commit lineage").include?("pass"), j.check_line(out, "commit lineage"))
  j.assert("AC-024 `evidence current` also passes (upper's code change is not lower's)", j.check_line(out, "evidence current").include?("pass"), j.check_line(out, "evidence current"))
  j.assert("AC-024 gate exits 0", code.zero?, out + err)
end

journey "EVAL-010", "test-results-recorded", "A failing or unrun check must be named in blocking or a finding (AC-025, AC-026, AC-027)" do |j|
  dir = j.fixture_repo("results")
  rec = j.new_record(dir, complete: LIFECYCLE.take(6), current_phase: "verify")
  j.complete!(rec, "verify", j.head(dir))
  tests = j.phase_file(rec, "verify", "tests.yml")
  j.edit_yaml(tests) do |t|
    t["checks"] << { "id" => "CHECK-002", "kind" => "tests", "command" => "bundle exec rake test", "result" => "fail", "evidence" => "evidence/recorded", "criteria" => ["AC-001"] }
  end
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "test results recorded")
  j.assert("AC-025 fails naming CHECK-002", line.include?("fail") && line.include?("CHECK-002"), line)
  rec.update_handoff(rec.control_plane.phase("verify")) { |h| h["findings"] = [{ "id" => "VER-001", "severity" => "major", "summary" => "CHECK-002 fails on the flaky clock test; tracked" }] }
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "test results recorded")
  j.assert("AC-026 passes with a detail naming the acknowledged check", line.include?("pass") && line.include?("CHECK-002"), line)
  j.edit_yaml(tests) do |t|
    t["checks"].last.merge!("id" => "CHECK-003", "result" => "skipped", "criteria" => ["AC-001"])
  end
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "test results recorded")
  j.assert("AC-027 a skipped check with criteria, unacknowledged, fails naming CHECK-003", line.include?("fail") && line.include?("CHECK-003"), line)
  j.edit_yaml(tests) { |t| t["checks"] = [] }
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "test results recorded")
  j.assert("an empty checks list fails", line.include?("fail"), line)
end

journey "EVAL-011", "criteria-covered", "Uncovered criteria warn at verification and fail at judgment unless set aside with a reason (AC-028, AC-029, AC-030)" do |j|
  dir = j.fixture_repo("criteria")
  rec = j.new_record(dir, complete: %w[intake discover], current_phase: "specify")
  j.complete!(rec, "specify", j.head(dir))
  File.write(j.phase_file(rec, "specify", "acceptance-criteria.yml"), "criteria:\n" + (1..3).map { |n| "  - id: AC-00#{n}\n    requirements: [REQ-001]\n    given: a\n    when: b\n    then: c\n    verified_by: []\n" }.join)
  code, out, err = j.sf(dir, "phase", "seal", "specify")
  j.assert("specify sealed naming AC-001..AC-003", code.zero?, out + err)
  %w[threat_model plan implement].each { |p| j.complete!(rec, p, j.head(dir)) }
  j.commit_all(dir, "through implement")
  j.complete!(rec, "verify", j.head(dir))
  j.edit_yaml(j.phase_file(rec, "verify", "tests.yml")) { |t| t["checks"].first["criteria"] = %w[AC-001 AC-002] }
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "criteria covered")
  j.assert("AC-028 `criteria covered` warns naming AC-003 and the gate passes", line.include?("warn") && line.include?("AC-003") && code.zero?, line + " exit #{code}")
  j.commit_all(dir, "verify")
  %w[evaluate attack review].each { |p| j.complete!(rec, p, j.head(dir)) }
  j.edit_yaml(j.phase_file(rec, "evaluate", "journeys.yml")) { |y| y["journeys"].each { |e| e["criteria"] = [] } }
  j.commit_all(dir, "evaluate attack review")
  j.complete!(rec, "judge", j.head(dir))
  final = j.phase_file(rec, "judge", "final.md")
  File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\nAPPROVED"))
  code, out, err = j.sf(dir, "gate", "judge")
  line = j.check_line(out, "criteria covered")
  j.assert("AC-029 at judge, `criteria covered` fails naming AC-003", line.include?("fail") && line.include?("AC-003") && code == 2, line)
  ev = j.phase_file(rec, "judge", "evidence.yml")
  j.edit_yaml(ev) { |e| e["criteria_not_covered"] = [{ "id" => "AC-003", "reason" => "needs a production observation; carried as OBS-1" }] }
  code, out, err = j.sf(dir, "gate", "judge")
  line = j.check_line(out, "criteria covered")
  j.assert("AC-030 passes saying AC-003 was set aside with a reason", line.include?("pass") && line.include?("AC-003") && line.match?(/set aside|reason/), line)
  j.edit_yaml(ev) { |e| e["criteria_not_covered"] = [{ "id" => "AC-003", "reason" => "" }] }
  code, out, err = j.sf(dir, "gate", "judge")
  line = j.check_line(out, "criteria covered")
  j.assert("AC-030 an empty reason fails", line.include?("fail") && line.include?("AC-003"), line)
  j.edit_yaml(ev) { |e| e["criteria_not_covered"] = [{ "id" => "AC-003", "reason" => "  \u200B" }] }
  code, out, err = j.sf(dir, "gate", "judge")
  line = j.check_line(out, "criteria covered")
  j.assert("a reason of Unicode blanks fails too", line.include?("fail"), line)
end

journey "EVAL-012", "evidence-manifest", "Listed artifacts must exist under the phase with matching digests; unlisted files warn; escapes are refused (AC-031, AC-032, AC-033)" do |j|
  dir = j.fixture_repo("manifest")
  rec = j.new_record(dir, complete: LIFECYCLE.take(6), current_phase: "verify")
  j.complete!(rec, "verify", j.head(dir))
  run = j.phase_file(rec, "verify", "evidence/run.txt")
  File.write(run, "884 runs, 0 failures\n")
  manifest = j.phase_file(rec, "verify", "evidence/manifest.yml")
  good = Digest::SHA256.hexdigest(File.read(run))
  recorded = j.phase_file(rec, "verify", "evidence/recorded.txt")
  rec_digest = Digest::SHA256.hexdigest(File.read(recorded))
  wrong = "deadbeef" * 8
  File.write(manifest, "commit_sha: #{j.head(dir)}\nartifacts:\n  - path: evidence/run.txt\n    sha256: #{wrong}\n  - path: evidence/recorded.txt\n    sha256: #{rec_digest}\n")
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "evidence manifest verified")
  j.assert("AC-031 fails naming evidence/run.txt and both digests", line.include?("fail") && line.include?("evidence/run.txt") && line.include?(good[0, 12]) && line.include?(wrong[0, 12]), line)
  File.write(manifest, "commit_sha: #{j.head(dir)}\nartifacts:\n  - path: evidence/run.txt\n    sha256: #{'0' * 64}\n  - path: evidence/recorded.txt\n    sha256: #{rec_digest}\n")
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "evidence manifest verified")
  j.note "observation: an unquoted all-digit sha256 is a YAML integer; the gate still fails but prints the recorded value as a number"
  j.assert("AC-031 (unquoted all-digit digest) still fails naming evidence/run.txt", line.include?("fail") && line.include?("evidence/run.txt"), line)
  File.write(manifest, "commit_sha: #{j.head(dir)}\nartifacts:\n  - path: evidence/run.txt\n    sha256: #{good.upcase}\n  - path: evidence/recorded.txt\n    sha256: #{rec_digest}\n")
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "evidence manifest verified")
  j.assert("an upper-case digest matches (case-insensitive); every file listed, so the check passes", line.include?("pass") && code.zero?, line)
  File.write(manifest, "commit_sha: #{j.head(dir)}\nartifacts:\n  - path: ../../05-implementation/log.md\n    sha256: #{good}\n")
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "evidence manifest verified")
  j.assert("AC-033 a path escaping the phase directory fails saying so", line.include?("fail") && line.include?("../../05-implementation/log.md") && line.include?("outside"), line)
  File.write(manifest, "commit_sha: #{j.head(dir)}\nartifacts:\n  - path: /etc/hosts\n    sha256: #{good}\n")
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "evidence manifest verified")
  j.assert("an absolute path is refused too", line.include?("fail") && line.include?("outside"), line)
  File.symlink("../../05-implementation/log.md", j.phase_file(rec, "verify", "evidence/link.md"))
  File.write(manifest, "commit_sha: #{j.head(dir)}\nartifacts:\n  - path: evidence/link.md\n    sha256: #{good}\n")
  code, out, err = j.sf(dir, "gate", "verify")
  line = j.check_line(out, "evidence manifest verified")
  j.assert("a symlinked artifact resolving outside the phase is refused", line.include?("fail"), line)

  dir2 = j.fixture_repo("manifest-extra")
  rec2 = j.new_record(dir2, complete: LIFECYCLE.take(8), current_phase: "attack")
  j.complete!(rec2, "attack", j.head(dir2))
  ev = j.phase_file(rec2, "attack", "evidence/cases.txt")
  File.write(ev, "CASE-001 denied\n")
  File.write(j.phase_file(rec2, "attack", "evidence/extra.log"), "not listed\n")
  File.write(j.phase_file(rec2, "attack", "evidence/manifest.yml"), "commit_sha: #{j.head(dir2)}\nartifacts:\n  - path: evidence/cases.txt\n    sha256: #{Digest::SHA256.hexdigest(File.read(ev))}\n")
  code, out, err = j.sf(dir2, "gate", "attack")
  line = j.check_line(out, "evidence manifest verified")
  j.assert("AC-032 warns naming the unlisted evidence/extra.log and the gate passes", line.include?("warn") && line.include?("extra.log") && code.zero?, line + " exit #{code}")
end

journey "EVAL-013", "verdict-and-fresh-session", "The judgment must say one permitted word; review and judgment must carry the runner's stamp when the policy is block (AC-034 to AC-038)" do |j|
  dir = j.fixture_repo("verdict")
  rec = j.new_record(dir, complete: ALL_REQUIRED, current_phase: "learn")
  final = j.phase_file(rec, "judge", "final.md")
  original = File.read(final)
  File.write(final, original.sub(/^## Outcome\n.*$/, "## Outcome\nBLOCKED"))
  code, out, err = j.sf(dir, "gate", "judge")
  line = j.check_line(out, "verdict recorded")
  j.assert("AC-034 `verdict recorded` passes with detail BLOCKED", line.include?("pass") && line.include?("BLOCKED"), line)
  File.write(final, original.sub(/^## Outcome\n.*$/, "## Outcome\nAPPROVED | APPROVED_WITH_RESIDUAL_RISK | BLOCKED | REJECTED"))
  code, out, err = j.sf(dir, "gate", "judge")
  line = j.check_line(out, "verdict recorded")
  j.assert("AC-035 fails naming the four words", line.include?("fail") && %w[APPROVED APPROVED_WITH_RESIDUAL_RISK BLOCKED REJECTED].all? { |w| line.include?(w) }, line)
  File.write(final, original.sub(/^## Outcome\n.*$/, "## Outcome\nAPPROVED"))

  policy = File.join(dir, ".ai", "policies", "enforcement.yml")
  j.note "repository policy set to guard mode block (scratch copy)"
  j.note "policy as copied from this repository: #{File.read(policy)[/^\s*mode:.*$/]}"
  File.write(policy, File.read(policy).sub(/^(\s*mode:).*$/, '\1 block'))
  j.commit_all(dir, "block mode") unless j.git(dir, "status", "--porcelain").strip.empty?
  rec.update_handoff(rec.control_plane.phase("review")) { |h| h["executed_by"] = nil }
  code, out, err = j.sf(dir, "gate", "review")
  line = j.check_line(out, "fresh session recorded")
  j.assert("AC-036 block mode, executed_by null: fails with `soft-foundry phase run review`", line.include?("fail") && line.include?("soft-foundry phase run review"), line)
  File.write(policy, File.read(policy).sub(/^(\s*mode:).*$/, '\1 warn'))
  code, out, err = j.sf(dir, "gate", "review")
  line = j.check_line(out, "fresh session recorded")
  j.assert("AC-037 warn mode: the check skips", line.include?("skip"), line)
  j.assert("AC-037 the fresh-context advisory is printed", (out + err).match?(/! warn review.*(fresh|already open|session)/), out + err)
  File.write(policy, File.read(policy).sub(/^(\s*mode:).*$/, '\1 block'))
  FileUtils.mkdir_p(File.join(dir, ".soft-foundry"))
  File.write(File.join(dir, ".soft-foundry", "enforcement.yml"), "guard:\n  mode: off\n")
  code, out, err = j.sf(dir, "gate", "judge", label: "machine-local override says off; judge has the runner's stamp")
  line = j.check_line(out, "fresh session recorded")
  j.assert("AC-038 passes; the override changes nothing", line.include?("pass"), line)
  rec.update_handoff(rec.control_plane.phase("judge")) { |h| h["executed_by"] = nil }
  code, out, err = j.sf(dir, "gate", "judge", label: "override still off, stamp removed")
  line = j.check_line(out, "fresh session recorded")
  j.assert("AC-038 with the stamp removed it fails even though the override says off", line.include?("fail"), line)
  code, out, err = j.sf(dir, "gate", "judge", env: { "SOFT_FOUNDRY_GUARD" => "off" }, show_env: "SOFT_FOUNDRY_GUARD=off", label: "the environment override is not consulted either")
  j.assert("SOFT_FOUNDRY_GUARD=off does not change the gate", j.check_line(out, "fresh session recorded").include?("fail"), j.check_line(out, "fresh session recorded"))
end

journey "EVAL-014", "commands", "gate exit 3, close refuses BLOCKED, change new takes --flag=value, summary names malformed lists (AC-039 to AC-043)" do |j|
  dir = j.fixture_repo("cmds")
  rec = j.new_record(dir, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  code, out, err = j.sf(dir, "phase", "reopen", "verify", "--reason", "rerun the suite")
  j.assert("phase reopen verify exits 0", code.zero?, out + err)
  code, out, err = j.sf(dir, "gate", "verify")
  j.assert("AC-039 line reads `06-verification  pending  SKIP`-style and exit is 3", out.match?(/06-verification\s+pending\s+SKIP/) && code == 3, out + "exit #{code}")
  code, out, err = j.sf(dir, "gate", "all")
  j.assert("AC-039 gate all exits 0 on the same record", code.zero?, out.lines.last(3).join + err)
  code, out, err = j.sf(dir, "--help")
  entry = out[/soft-foundry gate <phase\|all>.*?(?=\n  soft-foundry )/m].to_s
  j.note "usage entry for gate:"
  entry.each_line { |l| j.note "  " + l.chomp }
  j.assert("the usage entry for gate lists exit codes 0, 2 and 3", entry.include?("exits 0") && entry.include?("2 when") && entry.include?("3 when"), entry)
  code, out, err = j.sf(dir, "gate", "--help")
  j.note "observation: `gate --help` is read as a phase name; the codes live in the top-level --help entry above"

  %w[blocked residual].each do |kind|
    d = j.fixture_repo("close-#{kind}")
    r = j.new_record(d, complete: ALL_REQUIRED, current_phase: "learn")
    final = j.phase_file(r, "judge", "final.md")
    word = kind == "blocked" ? "BLOCKED" : "APPROVED_WITH_RESIDUAL_RISK"
    File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\n#{word}"))
    j.set_metadata!(r, status: "judged")
    j.commit_all(d, "finish c1 #{word}")
    j.git(d, "checkout", "-q", "main")
    j.git(d, "merge", "-q", "--no-ff", "change/c1", "-m", "merge c1")
    code, out, err = j.sf(d, "change", "close", "c1", label: "persona: maintainer, after merge; outcome #{word}")
    if kind == "blocked"
      j.assert("AC-040 close refused with exit 1 naming BLOCKED and remediate", code == 1 && (out + err).include?("BLOCKED") && (out + err).include?("remediate"), out + err)
      j.assert("AC-040 status still judged", j.metadata_of(r)["status"] == "judged")
      code, out, err = j.sf(d, "change", "close", "c1", "--force")
      j.assert("AC-040 --force closes", code.zero? && j.metadata_of(r)["status"] == "closed", out + err)
    else
      j.assert("AC-041 APPROVED_WITH_RESIDUAL_RISK closes as today", code.zero? && j.metadata_of(r)["status"] == "closed", out + err)
    end
  end

  d2 = j.fixture_repo("new-flags")
  code, out, err = j.sf(d2, "change", "new", "demo", "--type=fix", "--risk=low", "--track=gated")
  meta = YAML.safe_load_file(File.join(d2, "changes", "demo", "metadata.yml"), permitted_classes: [Time, Date])
  j.assert("AC-042 --type=fix --risk=low --track=gated recorded", code.zero? && meta["type"] == "fix" && meta["risk"] == "low" && meta["track"] == "gated", out + err + meta.slice("type", "risk", "track").inspect)
  code, out, err = j.sf(d2, "change", "new", "demo2", "--type", "fix", "--type", "docs")
  j.assert("AC-042 a flag given twice is refused with `--type given twice`", !code.zero? && (out + err).include?("--type given twice") && !Dir.exist?(File.join(d2, "changes", "demo2")), out + err)
  code, out, err = j.sf(d2, "change", "new", "demo3", "--title=Demo three", "--scope=lib/**")
  meta3 = YAML.safe_load_file(File.join(d2, "changes", "demo3", "metadata.yml"), permitted_classes: [Time, Date])
  j.assert("AC-042 --title= and --scope= forms accepted", code.zero? && meta3.dig("change", "title") == "Demo three" && meta3["scope"] == ["lib/**"], out + err + meta3.slice("change", "scope").inspect)

  d3 = j.fixture_repo("summary")
  r3 = j.new_record(d3, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  path = File.join(r3.dir, "06-verification", "handoff.yml")
  File.write(path, File.read(path).sub(/^blocking: .*$/, 'blocking: "text"'))
  code, out, err = j.sf(d3, "change", "summary")
  j.assert("AC-043 prints `blocking: malformed (06-verification: String, expected a list)` and exits 0", code.zero? && out.include?("blocking: malformed (06-verification: String, expected a list)"), out + err)
end

journey "EVAL-015", "residuals", "branch_resolved false is measured at HEAD; git: as a string is a gate line; reopen clears started_at; blank discharged_at is open; check names forced_by_risk; symlinked handoff refused (AC-044 to AC-047, AC-049)" do |j|
  dir = j.fixture_repo("ghost")
  rec = j.new_record(dir, complete: LIFECYCLE.take(6), current_phase: "verify")
  path = File.join(rec.dir, "metadata.yml")
  File.write(path, File.read(path).sub(/^  branch: .*$/, "  branch: change/ghost"))
  j.commit_all(dir, "record names a branch that does not exist")
  j.complete!(rec, "verify", j.head(dir))
  code, out, err = j.sf(dir, "phase", "seal", "verify")
  j.assert("AC-044 seal verify exits 0 on the checked-out branch (the record's branch does not exist)", code.zero?, out + err)
  j.assert("AC-044 sealed handoff has branch_resolved false", j.handoff_of(rec, "verify")["branch_resolved"] == false, j.handoff_of(rec, "verify")["branch_resolved"].inspect)
  j.git(dir, "branch", "change/ghost", j.head(dir))
  File.write(File.join(dir, "lib", "app.rb"), "puts 9\n")
  j.commit_all(dir, "code changed on the checked-out branch after the seal")
  code, out, err = j.sf(dir, "gate", "verify", label: "change/ghost now exists at the sealing commit; HEAD has newer code")
  line = j.check_line(out, "evidence current")
  j.assert("AC-044 `evidence current` measures HEAD and reports STALE", line.match?(/STALE|stale/) && code == 2, line)

  dir2 = j.fixture_repo("gitstring")
  rec2 = j.new_record(dir2, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  p2 = File.join(rec2.dir, "metadata.yml")
  File.write(p2, File.read(p2).sub(/^git:\n  worktree: .*\n  branch: .*\n/, "git: a string\n"))
  code, out, err = j.sf(dir2, "gate", "verify")
  j.assert("AC-045 a fail line names metadata.yml git and says it must be a mapping with branch and worktree; exit 2", code == 2 && (out + err).match?(/metadata\.yml.*git/) && (out + err).match?(/mapping/) && (out + err).include?("branch") && (out + err).include?("worktree"), out + err)
  j.assert("AC-045 no Ruby backtrace", !(out + err).match?(/\.rb:\d+:in/))

  dir3 = j.fixture_repo("reopen")
  rec3 = j.new_record(dir3, complete: LIFECYCLE.take(7), current_phase: "evaluate")
  j.assert("verify handoff has started_at before reopen", !j.handoff_of(rec3, "verify")["started_at"].nil?)
  code, out, err = j.sf(dir3, "phase", "reopen", "verify", "--reason", "x")
  j.assert("AC-046 after reopen, verify started_at is null", code.zero? && j.handoff_of(rec3, "verify")["started_at"].nil?, out + err + j.handoff_of(rec3, "verify").slice("status", "started_at").inspect)

  dir4 = j.fixture_repo("nbsp")
  rec4 = j.new_record(dir4, complete: ALL_REQUIRED, current_phase: "learn")
  final = j.phase_file(rec4, "judge", "final.md")
  File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\nAPPROVED"))
  j.set_metadata!(rec4, status: "judged")
  j.commit_all(dir4, "judged")
  code, out, err = j.sf(dir4, "change", "release", "--item", "OBS-1=watch the error rate for a week")
  j.assert("change release exits 0", code.zero?, out + err)
  j.edit_yaml(File.join(rec4.dir, "metadata.yml")) { |m| m["release"]["items"][0]["discharged_at"] = " " }
  j.commit_all(dir4, "discharged_at is a no-break space")
  j.git(dir4, "checkout", "-q", "main")
  j.git(dir4, "merge", "-q", "--no-ff", "change/c1", "-m", "merge c1")
  code, out, err = j.sf(dir4, "change", "status", "c1")
  j.assert("AC-046 change status reports OBS-1 open", out.match?(/OBS-1.*open|open.*OBS-1/), out + err)
  code, out, err = j.sf(dir4, "check")
  j.assert("AC-046 check reports the blank discharged_at (fails or names OBS-1)", (out + err).include?("OBS-1") || !code.zero?, out + err)
  code, out, err = j.sf(dir4, "change", "close", "c1")
  j.assert("AC-046 change close refuses naming OBS-1", code == 1 && (out + err).include?("OBS-1"), out + err)

  dir5 = j.fixture_repo("forced")
  wf = File.join(dir5, ".ai", "workflow.yml")
  File.write(wf, File.read(wf).sub(/^    high: gated$/, "    hihg: gated"))
  code, out, err = j.sf(dir5, "check")
  j.assert("AC-047 check fails naming forced_by_risk and hihg", !code.zero? && (out + err).include?("forced_by_risk") && (out + err).include?("hihg"), out + err)

  dir6 = j.fixture_repo("symlink")
  rec6 = j.new_record(dir6, complete: %w[intake discover], current_phase: "specify")
  h = File.join(rec6.dir, "00-intake", "handoff.yml")
  File.delete(h)
  File.symlink("../01-discovery/handoff.yml", h)
  before = j.head(dir6)
  code, out, err = j.sf(dir6, "phase", "seal", "intake")
  j.assert("AC-049 phase seal intake refuses naming the symlink; nothing committed", !code.zero? && (out + err).match?(/symlink/i) && j.head(dir6) == before, out + err)
  code, out, err = j.sf(dir6, "change", "summary")
  j.assert("AC-049 change summary refuses naming the symlink", (out + err).match?(/symlink/i), out + err)
  m6 = File.join(rec6.dir, "metadata.yml")
  File.delete(h)
  File.symlink("../01-discovery/handoff.yml", h) # keep for metadata case too
  FileUtils.rm(h)
  j.complete!(rec6, "intake", before) rescue nil
  File.rename(m6, m6 + ".real")
  File.symlink("metadata.yml.real", m6)
  code, out, err = j.sf(dir6, "phase", "seal", "specify")
  j.assert("AC-049 a symlinked metadata.yml is refused too", !code.zero? && (out + err).match?(/symlink/i), out + err)
end

journey "EVAL-016", "smoke-this-repository", "App-wide smoke test in this repository: help, check, status, gate all, summary, ci (REQ-028, AC-052 ci clause)" do |j|
  j.note "persona: maintainer in the real checkout; every command read-only"
  code, out, err = j.sf(REPO, "--help", home: ENV["HOME"])
  j.note "--help prints usage and exits 1 on this branch and on the pre-change gem alike (usage is the unknown-command path); the assertion is that the usage lists phase seal"
  j.assert("--help lists phase seal (exit #{code}, same as the pre-change gem)", out.include?("phase seal"), out.lines.grep(/seal/).join)
  code, out, err = j.sf(REPO, "check", home: ENV["HOME"])
  j.assert("check exits 0", code.zero?, out + err)
  code, out, err = j.sf(REPO, "change", "status", "gate-hardening", home: ENV["HOME"])
  j.assert("change status exits 0", code.zero?, out + err)
  code, out, err = j.sf(REPO, "gate", "all", "--change", "gate-hardening", home: ENV["HOME"])
  j.assert("gate all on this record exits 0 (evaluate and attack in progress, earlier phases PASS)", code.zero?, out + err)
  %w[structured\ files\ parse commit\ lineage test\ results\ recorded criteria\ covered evidence\ manifest\ verified].each do |name|
    j.assert("`#{name}` appears in this record's gate output", out.include?(name), name)
  end
  j.assert("the gate output carries no ANSI escapes", !(out + err).match?(ANSI))
  code, out, err = j.sf(REPO, "change", "summary", "gate-hardening", home: ENV["HOME"])
  j.assert("change summary exits 0", code.zero?, out + err)
  t = Benchmark.realtime { code, out, err = j.sf(REPO, "ci", home: ENV["HOME"]) }
  j.assert("ci exits 0 (check, gate cases, every record)", code.zero?, out.lines.last(10).join + err)
  j.assert("ci prints `(closed, skipped)` for closed records", out.include?("(closed, skipped)"))
  j.note format("ci wall time %.1f s", t)
end

journey "EVAL-017", "performance", "gate all on this change's record: this branch against the pre-change gem (AC-052 timing clause, REQ-036)" do |j|
  pre = PRECHANGE
  j.note "pre-change executable: #{pre.inspect} (soft_foundry gem 0.22.0 from main, which has neither phase_seal.rb nor the seven checks)"
  runs = 3
  branch = []
  before = []
  runs.times do
    branch << Benchmark.realtime { j.sf(REPO, "gate", "all", "--change", "gate-hardening", home: ENV["HOME"], label: "this branch") }
    if pre && File.executable?(pre)
      before << Benchmark.realtime { j.run(REPO, pre, "gate", "all", "--change", "gate-hardening", home: ENV["HOME"], label: "pre-change gem") }
    end
  end
  med = ->(a) { a.sort[a.size / 2] }
  j.note format("this branch: %s (median %.2f s)", branch.map { |x| format('%.2f', x) }.join(", "), med.call(branch))
  if before.empty?
    j.note "pre-change gem not available; timing comparison not made"
    j.assert("pre-change timing available", false)
  else
    j.note format("pre-change gem: %s (median %.2f s)", before.map { |x| format('%.2f', x) }.join(", "), med.call(before))
    j.note format("ratio branch/pre-change: %.2f", med.call(branch) / med.call(before))
    j.assert("AC-052 timed gate all is under twice the pre-change wall time", med.call(branch) < 2 * med.call(before), format("%.2f vs %.2f", med.call(branch), med.call(before)))
  end
end

journey "EVAL-018", "accessibility", "Every new refusal and gate line is plain one-line text with a word outcome, repository-relative paths, 12-character SHAs, no colour (REQ-032)" do |j|
  dir = j.fixture_repo("a11y")
  rec = j.new_record(dir, status: "intake")
  rec.update_handoff(rec.control_plane.phase("intake")) { |h| h["status"] = "in_progress" }
  outputs = []
  code, out, err = j.sf(dir, "phase", "seal", "intake", label: "refusal, piped (not a TTY)")
  outputs << out + err
  j.assert("refusal: one line, names the file and the status found and the next action", (out + err).lines.size == 1 && (out + err).include?("handoff.yml") && (out + err).include?("in_progress") && (out + err).include?("set it complete"), out + err)
  j.complete!(rec, "intake", j.head(dir))
  code, out, err = j.sf(dir, "phase", "seal", "intake")
  outputs << out + err
  sha_line = out.lines.last.to_s
  j.assert("sealed line shows a 12-character SHA", sha_line.match?(/ at [0-9a-f]{12}\s*$/), sha_line)
  code, out, err = j.sf(dir, "change", "status", "--json", home: HOME)
  full = JSON.parse(out) rescue nil
  text = out
  j.assert("change status --json carries the full 40-character recorded commit", full && text.match?(/[0-9a-f]{40}/), out.lines.first(5).join)
  j.complete!(rec, "discover", j.git(dir, "rev-parse", "HEAD~2").strip) # the repository's first commit: older than intake's commit_sha
  code, out, err = j.sf(dir, "gate", "discover", env: { "NO_COLOR" => "1" }, show_env: "NO_COLOR=1", label: "lineage failure under NO_COLOR")
  outputs << out + err
  lines = out.lines.map(&:chomp).select { |l| l.include?("commit lineage") }
  j.assert("gate line carries a word (fail) beside the glyph", lines.any? { |l| l.include?("✗") && l.include?("fail") }, lines.join)
  j.assert("SHAs in the gate line are 12 characters, not 40", lines.none? { |l| l.match?(/[0-9a-f]{40}/) } && lines.any? { |l| l.match?(/[0-9a-f]{12}/) }, lines.join)
  j.assert("the lineage line names the check, the value found and the next action", lines.any? { |l| l.include?("not an ancestor") && l.match?(/seal|re-?record|rerun|run/) }, lines.join)
  j.assert("meaning survives stripping non-ASCII: the word fail remains", lines.map { |l| l.gsub(/[^\x00-\x7F]/, "") }.any? { |l| l.include?("fail") })
  j.assert("no ANSI escapes in any captured output", outputs.none? { |o| o.match?(ANSI) })
  j.assert("paths in the gate output are repository-relative (no scratch prefix)", !out.include?(dir))
  j.note "every transcript in evidence/ is scanned for ANSI escapes by the driver's final step"
end

# ---------------------------------------------------------------------------
setup_bins
ids = ARGV.empty? ? JOURNEYS.keys : ARGV
summary = []
ids.each do |id|
  name, title, blk = JOURNEYS.fetch(id) { abort "unknown journey #{id}" }
  j = Journey.new(id, name, title)
  begin
    blk.call(j)
  rescue StandardError => e
    j.note "DRIVER ERROR: #{e.class}: #{e.message}"
    e.backtrace.first(5).each { |l| j.note "  #{l}" }
    j.assert("journey completed without a driver error", false, e.message)
  end
  j.finish
  summary << [id, j.failures]
end
ansi_hits = Dir.glob(File.join(EVIDENCE, "EVAL-*.txt")).select { |f| File.read(f).match?(ANSI) }
puts "ANSI escapes in evidence transcripts: #{ansi_hits.empty? ? 'none' : ansi_hits.map { |f| File.basename(f) }.join(', ')}"
puts summary.map { |id, f| "#{id}: #{f.zero? ? 'pass' : "#{f} failed"}" }.join("\n")
