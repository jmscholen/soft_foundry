# frozen_string_literal: true

require_relative "test_helper"

# Change 2: review and judgment prefer a different provider from the
# phases that wrote the code, and review findings that matter say what
# failure they prevent.
class CrossProviderReviewTest < Minitest::Test
  include FoundryFixture

  # A gated change with intake through attack complete; implementation's
  # handoff names `provider`.
  def with_reviewable_change(provider: "anthropic", slug: "c1")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug)
      record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: SoftFoundry::ControlPlane.new(dir))
      meta = File.join(record.dir, "metadata.yml")
      File.write(meta, File.read(meta).sub(/^status: intake.*$/, "status: in_progress").sub(/^current_phase: intake.*$/, "current_phase: attack"))
      commit_all(dir, "record")
      %w[intake discover specify threat_model plan implement verify evaluate attack].each { |id| complete_phase!(record, id, sha: head(dir)) }
      set_provider(record, "implement", provider) if provider
      commit_all(dir, "phases through attack")
      yield dir, record
    end
  end

  def set_provider(record, phase_id, provider, shell: nil)
    path = record.handoff_path(record.control_plane.phase(phase_id))
    h = YAML.safe_load_file(path)
    h["resolved_model"] = (h["resolved_model"] || {}).merge("provider" => provider)
    h["executed_by"] = { "shell" => shell } if shell
    File.write(path, YAML.dump(h))
  end

  # Fake executables on an otherwise empty PATH, so "installed" is exactly
  # the shells named.
  def with_installed(*shells)
    Dir.mktmpdir("sf-bin") do |bin|
      shells.each do |s|
        File.write(File.join(bin, s), "#!/bin/sh\nexit 0\n")
        File.chmod(0o755, File.join(bin, s))
      end
      with_env("PATH" => "#{bin}:/usr/bin:/bin") { yield }
    end
  end

  def dry_run(dir, *args)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env("ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "SOFT_FOUNDRY_BILLING" => nil) do
      code = SoftFoundry::CLI.new(["phase", "run", *args, "--dry-run"], out: out, err: err, root: dir).run
    end
    [code, out.string + err.string]
  end

  # --- policy -------------------------------------------------------------------

  def test_review_and_judgment_declare_the_preference_and_check_lints_it
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    %w[review final-judgment].each do |name|
      assert_equal %w[implement remediate], plane.skill(name).definition["prefer_different_provider_from"], name
    end
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai", "skills", "review", "skill.yml")
      File.write(path, File.read(path).sub("[implement, remediate]", "[implement, nonsense]"))
      code, out = cli(dir, "check")
      refute_equal 0, code
      assert_includes out, "prefer_different_provider_from names 'nonsense', which is not a lifecycle phase"
    end
  end

  # --- provider of a phase --------------------------------------------------------

  def test_provider_names_are_normalized_from_the_handoff_or_the_shell
    p = SoftFoundry::PhaseRunner
    assert_equal "anthropic", p.provider_of({ "resolved_model" => { "provider" => "Anthropic" } })
    assert_equal "xai", p.provider_of({ "resolved_model" => { "provider" => "xAI" } })
    assert_equal "xai", p.provider_of({ "resolved_model" => { "provider" => "x.ai" } })
    assert_equal "openai", p.provider_of({ "resolved_model" => { "provider" => "codex" } })
    assert_equal "openai", p.provider_of({ "resolved_model" => { "provider" => nil }, "executed_by" => { "shell" => "codex" } })
    assert_nil p.provider_of({ "resolved_model" => { "provider" => nil } })
    assert_nil p.provider_of({ "resolved_model" => { "provider" => "someone-else" } })
  end

  # --- runner default ---------------------------------------------------------------

  def test_review_without_shell_picks_the_first_installed_other_provider_and_says_why
    with_reviewable_change(provider: "anthropic") do |dir, _record|
      with_installed("claude", "codex", "grok") do
        code, out = dry_run(dir, "review")
        assert_equal 0, code, out
        assert_includes out, "would run review of c1 with: codex exec"
        assert_includes out, "shell: codex (implementation ran on anthropic; the review skill prefers a different provider)"
      end
      with_installed("claude", "grok") do
        _, out = dry_run(dir, "review")
        assert_includes out, "with: grok -s"
      end
    end
  end

  def test_remediation_counts_too
    with_reviewable_change(provider: "anthropic") do |dir, record|
      complete_phase!(record, "remediate", sha: head(dir))
      set_provider(record, "remediate", "openai")
      complete_phase!(record, "review", sha: head(dir))
      with_installed("claude", "codex", "grok") do
        _, out = dry_run(dir, "judge")
        assert_includes out, "with: grok -s"
        assert_includes out, "shell: grok (implementation ran on anthropic, remediation on openai; the final-judgment skill prefers a different provider)"
      end
    end
  end

  def test_with_no_other_provider_installed_it_warns_and_uses_what_there_is
    with_reviewable_change(provider: "anthropic") do |dir, _record|
      with_installed("claude") do
        code, out = dry_run(dir, "review")
        assert_equal 0, code, out
        assert_includes out, "with: claude -p"
        assert_includes out, "! warn shell: no installed shell runs on a provider other than anthropic, so review runs on claude"
      end
    end
  end

  def test_an_explicit_shell_wins_and_other_phases_keep_claude
    with_reviewable_change(provider: "anthropic") do |dir, _record|
      with_installed("claude", "codex", "grok") do
        _, out = dry_run(dir, "review", "--shell", "claude")
        assert_includes out, "with: claude -p"
        refute_includes out, "shell: "
      end
    end
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c2")
      cli(dir, "change", "new", "c2")
      commit_all(dir, "record")
      with_installed("claude", "codex", "grok") do
        _, out = dry_run(dir, "intake")
        assert_includes out, "with: claude -p"
      end
    end
  end

  def test_unknown_implementation_provider_keeps_claude_and_says_so
    with_reviewable_change(provider: nil) do |dir, _record|
      with_installed("claude", "codex", "grok") do
        _, out = dry_run(dir, "review")
        assert_includes out, "with: claude -p"
        assert_includes out, "! warn shell: the provider of implementation is not recorded"
      end
    end
  end

  # --- advisory ----------------------------------------------------------------------

  def test_a_review_on_the_same_provider_is_advised
    with_reviewable_change(provider: "anthropic") do |dir, record|
      complete_phase!(record, "review", sha: head(dir))
      set_provider(record, "review", "anthropic")
      notes = SoftFoundry::Advisory.new(record).notices.map(&:message)
      assert(notes.any? { |m| m.include?("review (13-review) ran on anthropic, the same provider as implementation") }, notes.join("\n"))
      set_provider(record, "review", "xAI")
      notes = SoftFoundry::Advisory.new(record).notices.map(&:message)
      refute(notes.any? { |m| m.include?("the same provider as") }, notes.join("\n"))
    end
  end

  # --- findings explained ---------------------------------------------------------------

  def review_with_findings(record, dir, findings)
    complete_phase!(record, "review", sha: head(dir))
    path = record.handoff_path(record.control_plane.phase("review"))
    h = YAML.safe_load_file(path)
    h["findings"] = findings
    File.write(path, YAML.dump(h))
    SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate(record.control_plane.phase("review"))
  end

  def check(result, name) = result.checks.find { |c| c.name == name }

  def test_blocking_and_major_findings_must_name_the_failure_they_prevent
    with_reviewable_change do |dir, record|
      result = review_with_findings(record, dir, [
        { "id" => "REV-1", "severity" => "major", "summary" => "s" },
        { "id" => "REV-2", "severity" => "blocking", "summary" => "s", "failure" => "  " },
        { "id" => "REV-3", "severity" => "minor", "summary" => "s" }
      ])
      c = check(result, "findings explained")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "REV-1"
      assert_includes c.detail, "REV-2"
      refute_includes c.detail, "REV-3"

      result = review_with_findings(record, dir, [
        { "id" => "REV-1", "severity" => "major", "summary" => "s", "failure" => "a planted ledger line with ; in its id makes a pasted resume command run a second command" },
        { "id" => "REV-3", "severity" => "minor", "summary" => "s" }
      ])
      assert_equal :pass, check(result, "findings explained").outcome
    end
  end

  def test_templates_and_skill_text_carry_the_rule
    dir = File.join(REPO_ROOT, ".ai", "skills", "review")
    %w[functional architecture security accessibility infrastructure operations].each do |f|
      assert_includes File.read(File.join(dir, "template", "#{f}.md")), "Failure it prevents", f
    end
    skill = File.read(File.join(dir, "SKILL.md"))
    assert_includes skill, "minor at most"
    assert_includes skill, "defensive"
    assert_includes File.read(File.join(REPO_ROOT, ".ai", "templates", "handoff.yml")), "failure:"
  end
  # FIND-ATK-001: a serious finding under any other severity word must not
  # skip the check. Only minor findings may go without a failure.
  def test_any_severity_but_minor_must_name_its_failure
    with_reviewable_change do |dir, record|
      result = review_with_findings(record, dir, [
        { "id" => "REV-C", "severity" => "critical", "summary" => "s" },
        { "id" => "REV-H", "severity" => "High", "summary" => "s" },
        { "id" => "REV-N", "summary" => "no severity at all" },
        { "id" => "REV-M", "severity" => "Minor", "summary" => "s" }
      ])
      c = check(result, "findings explained")
      assert_equal :fail, c.outcome
      %w[REV-C REV-H REV-N].each { |id| assert_includes c.detail, id }
      refute_includes c.detail, "REV-M"
    end
  end
end
