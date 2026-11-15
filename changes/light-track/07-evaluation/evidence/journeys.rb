# frozen_string_literal: true

# Evaluation journeys for changes/light-track.
# Usage: ruby journeys.rb <repository root> <EVAL-001 ... EVAL-009>
# Prints the transcript of one journey; exits 1 when an assertion fails.
require_relative "lib"

LIGHT = %w[intake specify implement verify review judge].freeze
LIGHT_OPTIONAL = %w[01-discovery 03-threat-model 04-plan 07-evaluation 08-attack 15-learning].freeze
GATED = %w[intake discover specify threat_model plan implement verify evaluate attack review judge learn].freeze

def current_phase(dir, slug) = YAML.safe_load_file(File.join(dir, "changes", slug, "metadata.yml"), permitted_classes: [Time, Date])["current_phase"]
def status_of(dir, slug) = YAML.safe_load_file(File.join(dir, "changes", slug, "metadata.yml"), permitted_classes: [Time, Date])["status"]

# A person creates the record; the agent works each phase and seals it.
def build(dir, slug, track, phases:, risk: "medium", show: false, before: {})
  sh(dir, "git", "checkout", "-qb", "change/#{slug}")
  code, = sf(dir, "change", "new", slug, "--track", track, quiet: !show)
  raise "change new failed" unless code.zero?
  set_metadata(dir, slug) { |m| m["risk"] = risk; m["type"] = "feature" }
  commit(dir, "record")
  phases.each do |ph|
    before[ph]&.call
    do_phase(dir, slug, ph)
    code, out = sf(dir, "phase", "seal", ph, quiet: !show)
    raise "seal #{ph} failed on #{track}:\n#{out}" unless code.zero?
    say "  current_phase is now: #{current_phase(dir, slug)}" if show
  end
end

# A phase done again after a reset: its evidence differs from the last seal.
def redo_phase(dir, slug, phase, file, note)
  do_phase(dir, slug, phase)
  path = File.join(record(dir, slug).phase_dir(plane(dir).phase(phase)), file)
  File.write(path, "#{File.read(path)}\n#{note}\n")
  sf(dir, "phase", "seal", phase, quiet: true)
end

def line_for(out, name) = out.lines.find { |l| l.include?(name) }.to_s.strip

# --- EVAL-001 (AC-001) --------------------------------------------------------
def eval_001
  step "Maintainer creates a change on the light track at medium risk; the agent works and seals only the required phases"
  with_repo do |dir|
    sh(dir, "git", "checkout", "-qb", "change/l1")
    code, out = sf(dir, "change", "new", "l1", "--track", "light")
    expect("change new --track light exits 0 and says track: light", code.zero? && out.include?("track: light"))
    set_metadata(dir, "l1") { |m| m["risk"] = "medium"; m["type"] = "feature" }
    commit(dir, "record")
    seen = []
    LIGHT.each do |ph|
      do_phase(dir, "l1", ph)
      code, = sf(dir, "phase", "seal", ph)
      seen << [ph, code, current_phase(dir, "l1")]
      say "  current_phase is now: #{seen.last.last}"
    end
    expect("every required phase sealed (exit 0)", seen.all? { |_, c, _| c.zero? })
    expect("each seal advanced straight to the next required phase, stepping over the optional ones (specify, implement, verify, review, judge)",
           seen.first(5).map(&:last) == %w[specify implement verify review judge])
    expect("after judgment the record is judged", status_of(dir, "l1") == "judged")
    say sh(dir, "git", "log", "--oneline").lines.map { |l| "  #{l}" }.join

    step "Gate every phase on the branch"
    code, out = sf(dir, "gate", "all")
    expect("gate all exits 0", code.zero?)
    expect("no check fails", failing_checks(out).empty?)
    skipped = out.lines.each_cons(2).select { |a, _| a =~ /pending\s+SKIP/ }.map { |a, _| a.split.first }
    expect("the six track-optional phases are pending and skipped, not failed", (LIGHT_OPTIONAL - skipped).empty?)

    step "Merge, then gate and close on main"
    sh(dir, "git", "checkout", "-q", "main")
    sh(dir, "git", "merge", "-q", "--no-ff", "change/l1", "-m", "merge l1")
    code, out = sf(dir, "gate", "all", "--change", "l1", quiet: true)
    expect("gate all after merge exits 0 with no failing check", code.zero? && failing_checks(out).empty?)
    code, out = sf(dir, "change", "close", "l1")
    expect("change close exits 0 and reports closed", code.zero? && out.include?("closed"))
    code, out = sf(dir, "change", "status", "l1")
    expect("status after close shows closed on the light track", code.zero? && out.include?("closed") && out.include?("track: light"))
  end

  step "The same record on the gated track"
  with_repo do |dir|
    sh(dir, "git", "checkout", "-qb", "change/g1")
    sf(dir, "change", "new", "g1", "--track", "gated", quiet: true)
    set_metadata(dir, "g1") { |m| m["risk"] = "medium"; m["type"] = "feature" }
    commit(dir, "record")
    do_phase(dir, "g1", "intake")
    sf(dir, "phase", "seal", "intake", quiet: true)
    do_phase(dir, "g1", "specify")
    code, out = sf(dir, "phase", "seal", "specify")
    expect("phase seal specify is refused on the gated track while discovery is pending", !code.zero? && line_for(out, "predecessor complete") =~ /fail/)
    (LIGHT - %w[intake specify]).each { |ph| do_phase(dir, "g1", ph) }
    set_metadata(dir, "g1") { |m| m["status"] = "in_progress"; m["current_phase"] = "judge" }
    commit(dir, "the same six phases complete, the other six pending")
    code, out = sf(dir, "gate", "all")
    fails = failing_checks(out)
    expect("gate all exits 2 on the gated record", code == 2)
    expect("the failures are predecessor complete, naming a pending phase", !fails.empty? && fails.all? { |l| l.include?("predecessor complete") && l.include?("pending") })
    sh(dir, "git", "checkout", "-q", "main")
    sh(dir, "git", "merge", "-q", "--no-ff", "change/g1", "-m", "merge g1")
    code, = sf(dir, "change", "close", "g1")
    expect("change close refuses the gated record", !code.zero?)
  end
end

# --- EVAL-002 (AC-002) --------------------------------------------------------
def remediation_cap(track, phases, slug, unfinished:)
  with_repo do |dir|
    build(dir, slug, track, phases: phases)
    step "#{track}: round 1 sealed, then review sends it back"
    redo_phase(dir, slug, "remediate", "summary.md", "round 1")
    code, = sf(dir, "phase", "reopen", "remediate", "--reason", "review found more")
    expect("#{track}: reopen after one round is allowed", code.zero?)
    commit(dir, "reopened")
    if unfinished
      step "#{track}: a remediation is started and reopened before it completes"
      path = File.join(dir, "changes", slug, "09-remediation", "handoff.yml")
      File.write(path, File.read(path).sub(/^status: .*$/, "status: in_progress"))
      commit(dir, "remediation started")
      code, = sf(dir, "phase", "reopen", "remediate", "--reason", "started over before finishing")
      expect("#{track}: reopening the unfinished remediation is allowed", code.zero?)
      commit(dir, "reopened unfinished")
    end
    step "#{track}: round 2 sealed, verification and review redone"
    redo_phase(dir, slug, "remediate", "summary.md", "round 2")
    redo_phase(dir, slug, "verify", "results.md", "after round 2")
    redo_phase(dir, slug, "review", "consolidated.md", "after round 2")
    code, out = sf(dir, "gate", "review", quiet: true)
    say "  #{line_for(out, 'remediation within cap')}"
    expect("#{track}: gate review passes and counts 2 remediation rounds (limit 2)", code.zero? && line_for(out, "remediation within cap").include?("2 remediation rounds"))
    step "#{track}: a reset that includes remediation is requested at the cap"
    code, out = sf(dir, "phase", "reopen", "remediate", "--reason", "third try")
    expect("#{track}: the reopen is refused", !code.zero?)
    expect("#{track}: the message says remediation cap and '2 remediation rounds', and does not say sealed", out.include?("remediation cap") && out.include?("2 remediation rounds") && !out.include?("sealed"))
    say "  status is now: #{status_of(dir, slug)}"
    expect("#{track}: the change is parked awaiting_human", status_of(dir, slug) == "awaiting_human")
    step "#{track}: a third round is recorded anyway, with no cap decision"
    path = File.join(dir, "changes", slug, "09-remediation", "summary.md")
    File.write(path, "#{File.read(path)}\nround 3\n")
    sh(dir, "git", "add", "-A")
    sh(dir, "git", "commit", "-q", "-m", "Record #{slug} remediate")
    code, out = sf(dir, "gate", "review", quiet: true)
    say "  #{line_for(out, 'remediation within cap')}"
    expect("#{track}: gate review fails on remediation within cap", code == 2 && line_for(out, "remediation within cap") =~ /fail/)
    line_for(out, "remediation within cap")
  end
end

def eval_002
  through_review = { "light" => LIGHT - %w[judge], "gated" => GATED - %w[judge learn] }
  full = { "light" => LIGHT, "gated" => GATED }
  results = {}
  %w[light gated].each do |track|
    with_repo do |dir|
      build(dir, "c1", track, phases: full[track])
      step "#{track}: must criteria with no approval"
      set_metadata(dir, "c1") { |m| m["human_decisions"] = [] }
      code, out = sf(dir, "gate", "specify", quiet: true)
      say "  #{line_for(out, 'must criteria approved')}"
      results[[track, :approval]] = [code, line_for(out, "must criteria approved") =~ /fail/ ? "fail" : "pass"]
      sh(dir, "git", "checkout", "--", "changes/c1/metadata.yml")
      step "#{track}: specification edited after its seal"
      path = File.join(dir, "changes", "c1", "02-specification", "specification.md")
      File.write(path, "#{File.read(path)}\nA requirement added after the lock.\n")
      commit(dir, "edit the specification")
      code, out = sf(dir, "gate", "specify", quiet: true)
      say "  #{line_for(out, 'specification locked')}"
      results[[track, :lock]] = [code, line_for(out, "specification locked") =~ /fail/ ? "fail" : "pass"]
    end
    results[[track, :cap]] = remediation_cap(track, through_review[track], "c2", unfinished: false)
  end
  say
  %i[approval lock].each do |state|
    expect("light: #{state} state fails its check with exit 2", results[["light", state]] == [2, "fail"])
    expect("gated: #{state} state fails the same check", results[["gated", state]] == [2, "fail"])
  end

  step "risk high on the light track"
  with_repo do |dir|
    sh(dir, "git", "checkout", "-qb", "change/h1")
    sf(dir, "change", "new", "h1", "--track", "light", quiet: true)
    set_metadata(dir, "h1") { |m| m["risk"] = "high"; m["type"] = "feature" }
    commit(dir, "record at high risk")
    do_phase(dir, "h1", "intake")
    code, out = sf(dir, "gate", "intake", quiet: true)
    say "  #{line_for(out, 'track permitted')}"
    expect("gate intake exits 2 on track permitted, naming gated", code == 2 && line_for(out, "track permitted") =~ /fail/ && line_for(out, "track permitted").include?("gated"))
    code, out = sf(dir, "phase", "seal", "intake", quiet: true)
    say "  #{out.lines.last.to_s.strip}"
    expect("phase seal intake commits nothing", !code.zero? && sh(dir, "git", "log", "--oneline").lines.none? { |l| l.include?("Record h1") })
    sf(dir, "change", "status", "h1")
  end
  with_repo do |dir|
    sh(dir, "git", "checkout", "-qb", "change/h2")
    sf(dir, "change", "new", "h2", "--track", "gated", quiet: true)
    set_metadata(dir, "h2") { |m| m["risk"] = "high"; m["type"] = "feature" }
    commit(dir, "record at high risk")
    do_phase(dir, "h2", "intake")
    code, out = sf(dir, "gate", "intake", quiet: true)
    say "  #{line_for(out, 'track permitted')}"
    expect("a gated record at high risk passes track permitted", line_for(out, "track permitted") =~ /pass/)
  end
end

# --- EVAL-003 (AC-003) --------------------------------------------------------
def eval_003
  with_repo do |dir|
    change_app = -> { File.write(File.join(dir, "lib", "app.rb"), "puts 2\n"); commit(dir, "GREEN: change lib/app.rb") }
    build(dir, "c1", "light", phases: LIGHT - %w[judge], before: { "implement" => change_app })
    rules = YAML.safe_load_file(File.join(dir, "changes", "c1", "metadata.yml"), permitted_classes: [Time, Date])["rules"]
    expect("the record is under the new rules (rules: 2)", rules == 2)
    handoff = File.join(dir, "changes", "c1", "13-review", "handoff.yml")
    finding = lambda do |path|
      data = YAML.safe_load_file(handoff, permitted_classes: [Time, Date])
      data["findings"] = [{ "id" => "REV-001", "severity" => "major", "summary" => "a weakness said to be outside the change", "failure" => "input x gives the wrong result y",
                            "outside_change" => true, "follow_up" => "a follow-up change", "paths" => [path] }]
      File.write(handoff, YAML.dump(data))
    end
    absolute = File.join(File.realpath(dir), "lib", "app.rb")
    step "A review finding marked outside_change names the modified file in six spellings"
    ["./lib/app.rb", "lib//app.rb", "lib/./app.rb", "lib/x/../app.rb", absolute, "lib/*.rb"].each do |spelling|
      finding.call(spelling)
      code, out = sf(dir, "gate", "review", quiet: true)
      line = line_for(out, "outside-change findings").gsub(File.realpath(dir), "<repo>")
      say "  #{line}"
      expect("#{spelling.sub(File.realpath(dir), '<repo>').inspect}: gate review exits 2, outside-change findings fails and names the path", code == 2 && line =~ /fail/ && line.include?(spelling.sub(File.realpath(dir), "<repo>")))
    end
    step "A path the change did not modify"
    ["lib/other.rb", "./lib/other.rb"].each do |spelling|
      finding.call(spelling)
      code, out = sf(dir, "gate", "review", quiet: true)
      say "  #{line_for(out, 'outside-change findings')}"
      expect("#{spelling.inspect}: outside-change findings passes and gate review exits 0", code.zero? && line_for(out, "outside-change findings") =~ /pass/)
    end
    step "Spellings the criterion does not list (reported, not asserted as criteria)"
    ["lib/app.rb", "lib/app.rb ", "../outside.rb", "lib/../../x.rb", "lib/app.r?", "LIB/app.rb", "lib\\app.rb"].each do |spelling|
      finding.call(spelling)
      code, out = sf(dir, "gate", "review", quiet: true)
      say "  #{spelling.inspect}: exit #{code}: #{line_for(out, 'outside-change findings')}"
    end
  end
end

# --- EVAL-004 (AC-004) --------------------------------------------------------
def eval_004
  remediation_cap("light", LIGHT - %w[judge], "c1", unfinished: true)
end

# --- EVAL-005 (AC-005) --------------------------------------------------------
def text_edits(dir)
  File.write(File.join(dir, "README.md"), "# readme\n")
  FileUtils.mkdir_p(File.join(dir, "docs"))
  File.write(File.join(dir, "docs", "guide.md"), "guide\n")
  skill = File.join(dir, ".ai", "skills", "review", "SKILL.md")
  File.write(skill, "#{File.read(skill)}\nOne more sentence.\n")
  File.write(File.join(dir, "changes", "c1", "05-implementation", "log.md"), "log\n")
  commit(dir, "text only")
end

def eval_005
  with_repo do |dir|
    build(dir, "c1", "light", phases: %w[intake specify])
    step "The change modifies README.md, docs/, its own record and a control-plane skill's prose"
    text_edits(dir)
    say sh(dir, "git", "diff", "--name-only", "HEAD~1", "HEAD").lines.map { |l| "  changed: #{l}" }.join
    say "  git status --short --ignored: #{sh(dir, 'git', 'status', '--short', '--ignored').strip.inspect}"
    code, out = sf(dir, "change", "size", "--phase", "verify")
    expect("the smaller verify size is reported with a documentation-only reason", code.zero? && out.include?("size: targeted_plus_full_before_merge") && out.include?("documentation-only"))

    step "Control: the same repository with the tool's ignored machine-local directory (.soft-foundry/, written by phase seal) removed"
    FileUtils.rm_rf(File.join(dir, ".soft-foundry"))
    code, out = sf(dir, "change", "size", "--phase", "verify")
    expect("control: the smaller verify size is reported with a documentation-only reason", code.zero? && out.include?("size: targeted_plus_full_before_merge") && out.include?("documentation-only"))
    expect("control: the reason still asks for the control plane check and the harness evals", out.include?("soft-foundry check") && out.include?("soft-foundry eval"))
    step "Control: adding a path under lib/"
    File.write(File.join(dir, "lib", "app.rb"), "puts 3\n")
    commit(dir, "code")
    code, out = sf(dir, "change", "size", "--phase", "verify")
    expect("the largest verify size is reported again", code.zero? && out.include?("size: full_at_verify"))
  end
  step "The same text-only change with --since, in a repository where any command has taken the record lock"
  with_repo do |dir|
    build(dir, "c1", "light", phases: %w[intake specify])
    base = head(dir)
    text_edits(dir)
    code, out = sf(dir, "change", "size", "--phase", "verify", "--since", base)
    expect("with --since: the smaller verify size is reported", code.zero? && out.include?("size: targeted_plus_full_before_merge"))
  end
end

# --- EVAL-010: app-wide smoke with light records present ------------------------
def eval_010
  with_repo do |dir|
    build(dir, "done1", "light", phases: LIGHT)
    sh(dir, "git", "checkout", "-q", "main")
    sh(dir, "git", "merge", "-q", "--no-ff", "change/done1", "-m", "merge done1")
    sf(dir, "change", "close", "done1", quiet: true)
    commit(dir, "close done1")
    build(dir, "open1", "light", phases: %w[intake specify implement])
    step "Commands that read every record, with one closed and one open light-track record"
    code, = sf(dir, "check")
    expect("check exits 0", code.zero?)
    code, out = sf(dir, "change", "list")
    expect("change list exits 0 and lists both records", code.zero? && out.include?("done1") && out.include?("open1"))
    code, json = sf(dir, "change", "list", "--json", quiet: true)
    expect("change list --json parses", code.zero? && JSON.parse(json))
    code, = sf(dir, "scan", quiet: true)
    expect("scan exits 0", code.zero?)
    code, out = sf(dir, "gate", "all")
    expect("gate all on the open record exits 0: complete phases pass, pending ones are skipped", code.zero? && failing_checks(out).empty?)
    code, out = sf(dir, "gate", "evaluate")
    expect("gate evaluate on a pending track-optional phase exits 3 (nothing to pass), not 2", code == 3)
    code, out = sf(dir, "change", "size", "--phase", "evaluate")
    expect("change size --phase evaluate still answers on a light record", code.zero? && out.include?("size:"))
    code, out = sf(dir, "phase", "run", "verify", "--dry-run", quiet: true)
    say "  #{out.lines.first.to_s.strip[0, 160]}"
    expect("phase run verify --dry-run accepts the next required phase", code.zero?)
    code, out = sf(dir, "ci")
    expect("ci exits 0 with light records present", code.zero?)
    step "What the JSON form says of a stepped-over phase (observation)"
    _, json = sf(dir, "change", "status", "open1", "--json", quiet: true)
    data = JSON.parse(json)
    gate = Array(data["gates"]).find { |g| g.to_s.include?("01-discovery") }
    say "  01-discovery in --json: #{gate.to_s[0, 400]}"
  end
end

# --- EVAL-006, EVAL-007 (AC-006, AC-007): what a reader finds ------------------
def excerpt(path, pattern, around: 0)
  lines = File.readlines(File.join(ROOT, path))
  hits = lines.each_index.select { |i| lines[i] =~ pattern }
  say "#{path}: #{hits.size} matching line(s)"
  hits.each { |i| (i - around..i + around).each { |j| say "  #{j + 1}: #{lines[j].rstrip}" if j >= 0 && lines[j] } }
  hits.map { |i| lines[i] }.join
end

def eval_006
  step "Review skill"
  text = excerpt(".ai/skills/review/SKILL.md", /write access|alteration|altered/i)
  expect("the review skill speaks of a weakness needing repository write access", text =~ /write access/i)
  expect("the review skill speaks separately of an observed alteration of evidence", text =~ /alter/i)
  step "Adversarial-testing skill"
  text = excerpt(".ai/skills/adversarial-testing/SKILL.md", /metadata\.yml/)
  expect("the attack skill names the metadata.yml gap", text.include?("metadata.yml"))
end

def eval_007
  step "soft-foundry help"
  with_repo do |dir|
    code, out = sf(dir, "help", quiet: true)
    hits = out.lines.select { |l| l =~ /light/i }
    hits.each { |l| say "  #{l.rstrip}" }
    say "  (help exits #{code}; the gem installed before this change exits the same, so the exit status is not this change's)"
    expect("help names the light track", out.include?("--track gated|iterative|light"))
    expect("help names the light track's required phases", hits.join =~ /intake.*specif.*implement.*verif.*review.*judg/im)
    expect("help names the locks the light track keeps", hits.join =~ /lock/i)
    expect("help names the high-risk exclusion", hits.join =~ /high/i)
  end
  step ".ai/workflow.yml tracks section"
  lines = File.readlines(File.join(ROOT, ".ai", "workflow.yml"))
  from = lines.index { |l| l =~ /^  light:/ }
  section = lines[from, 11].join
  say section.lines.map { |l| "  #{l}" }.join
  expect("workflow.yml names the phases the track leaves optional (the rest are required)", section.include?("optional: [discover, threat_model, plan, evaluate, attack, learn]"))
  expect("workflow.yml names the locks kept", section =~ /specification\s+#?\s*lock/m && section.include?("must-criteria approval") && section.include?("remediation cap"))
  expect("workflow.yml names the high-risk exclusion", section =~ /high risk/i && section.include?("high: gated"))
end

# --- EVAL-008 (AC-008) --------------------------------------------------------
def eval_008
  with_repo do |dir|
    build(dir, "c1", "light", phases: %w[intake specify implement])
    step "change status, colour off, not a terminal"
    code, out = sf(dir, "change", "status", "c1")
    expect("no escape sequence is emitted", !out.include?("\e"))
    plain = out.gsub(/[^\x20-\x7E\n]/, "")
    step "the same output with every non-ASCII character removed"
    say plain.lines.map { |l| "  #{l}" }.join
    expect("the track is shown", plain.include?("track: light"))
    LIGHT_OPTIONAL.each do |name|
      expect("#{name} is labelled in words as optional on the light track", plain.lines.find { |l| l.include?(name) }.to_s.include?("optional on the light track"))
    end
    expect("phases optional on every track are labelled optional, without the track", plain.lines.find { |l| l.include?("09-remediation") }.to_s.strip.end_with?("optional"))
    expect("required pending phases carry no optional label", %w[06-verification 13-review 14-judgment].none? { |n| plain.lines.find { |l| l.include?(n) }.to_s.include?("optional") })
    expect("one phase per line, each starting with its directory name", plain.lines.count { |l| l =~ /^  \d\d-[a-z-]+\s+(pending|complete)/ } == 16)
    step "machine-readable form"
    code, json = sf(dir, "change", "status", "c1", "--json", quiet: true)
    data = JSON.parse(json)
    say "  track in --json: #{data['track'].inspect}"
    expect("--json carries the track by name", data.dig("track", "name") == "light")
    step "change list"
    sf(dir, "change", "list")
  end
end

# --- EVAL-009 (AC-009) --------------------------------------------------------
def eval_009
  with_repo do |dir|
    step "An unknown track name"
    sh(dir, "git", "checkout", "-qb", "change/n1")
    code, out = sf(dir, "change", "new", "n1", "--track", "nosuch")
    expect("change new --track nosuch is refused", !code.zero? && !File.exist?(File.join(dir, "changes", "n1")))
    expect("the message lists gated, iterative and light", %w[gated iterative light].all? { |n| out.include?(n) })
    step "No --track: the default track is unchanged"
    code, out = sf(dir, "change", "new", "n1")
    expect("the record is on the gated track", code.zero? && out.include?("track: gated"))
    code, out = sf(dir, "change", "status", "n1")
    expect("no phase of a gated record is labelled optional on a track", !out.include?("optional on the"))
    commit(dir, "n1")
    step "The iterative track still starts in exploring"
    sh(dir, "git", "checkout", "-qb", "change/i1", "main")
    code, out = sf(dir, "change", "new", "i1", "--track", "iterative")
    expect("the record is on the iterative track", code.zero? && out.include?("track: iterative"))
    code, out = sf(dir, "change", "status", "i1")
    expect("its status is exploring", out.include?("exploring"))
  end
  step "A gated record still runs its whole lifecycle and closes"
  with_repo do |dir|
    build(dir, "g1", "gated", phases: GATED)
    code, out = sf(dir, "gate", "all", quiet: true)
    expect("gate all exits 0 with no failing check", code.zero? && failing_checks(out).empty?)
    expect("current_phase walked every phase in order (no phase was stepped over that the gated track requires)", out.lines.count { |l| l =~ /complete\s+PASS/ } == 12)
    sh(dir, "git", "checkout", "-q", "main")
    sh(dir, "git", "merge", "-q", "--no-ff", "change/g1", "-m", "merge g1")
    code, out = sf(dir, "change", "close", "g1")
    expect("change close exits 0", code.zero? && out.include?("closed"))
  end
  step "A record created before this change (no rules line, no track line)"
  with_repo do |dir|
    sh(dir, "git", "checkout", "-qb", "change/old")
    sf(dir, "change", "new", "old", quiet: true)
    path = File.join(dir, "changes", "old", "metadata.yml")
    File.write(path, File.read(path).lines.reject { |l| l =~ /^(rules|track):/ }.join)
    commit(dir, "legacy record")
    code, out = sf(dir, "change", "status", "old")
    expect("status works and no phase is labelled optional on a track", code.zero? && !out.include?("optional on the"))
    do_phase(dir, "old", "intake")
    code, out = sf(dir, "gate", "intake", quiet: true)
    say "  #{line_for(out, 'track permitted')}"
    expect("gate intake passes", code.zero?)
  end
end

require "json"
name = ARGV.fetch(1)
say "# #{name} at #{sh(ROOT, 'git', 'rev-parse', 'HEAD').strip}"
send("eval_#{name[/\d+/]}")
finish(name)
