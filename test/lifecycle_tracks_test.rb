# frozen_string_literal: true

require_relative "test_helper"

# The gated and iterative lifecycle tracks (.ai/workflow.yml tracks:): an
# exploring stage that produces a journal but never evidence, `change vet`
# as the person's recorded acceptance that locks the specification, and
# `change reopen` back to exploring.
class LifecycleTracksTest < Minitest::Test
  include FoundryFixture

  # An exploring iterative change on its own branch, scaffolded and committed.
  def with_exploring_change(slug = "it1")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      code, out = cli(dir, "change", "new", slug, "--title", "x", "--track", "iterative")
      assert_equal 0, code, out
      commit_all(dir, "scaffold #{slug}")
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane)
      yield dir, plane, record
    end
  end

  # Everything `change vet` requires: risk classified, intake and the
  # specification complete and committed, one journal entry.
  def make_vettable!(dir, record, risk: "low")
    edit_metadata(dir, record) { |m| m.sub(/^risk: TBD.*$/, "risk: #{risk}") }
    complete_phase!(record, "intake", sha: head(dir))
    complete_phase!(record, "specify", sha: head(dir))
    journal(record, [{ "at" => "2026-09-16T00:00:00Z", "asked" => "try it", "changed" => "did", "commit" => head(dir),
                       "deployed" => { "environment" => "development" }, "outcome" => "accepted" }])
    commit_all(dir, "explored")
  end

  def edit_metadata(dir, record)
    path = File.join(record.dir, "metadata.yml")
    File.write(path, yield(File.read(path)))
  end

  def journal(record, entries)
    File.write(record.iterations_path, YAML.dump("iterations" => entries))
  end

  def fail_names(out) = out.lines.grep(/✗ fail/).map(&:strip)

  # --- control plane -------------------------------------------------------

  def test_repository_declares_both_tracks_with_gated_as_default
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    assert_equal %w[gated iterative], plane.track_names
    assert_equal "gated", plane.default_track
    refute plane.track("gated").exploring?
    iterative = plane.track("iterative")
    assert iterative.exploring?
    assert_equal "exploration", iterative.skill
    assert_equal "exploration", iterative.output
    assert_equal %w[intake specify], iterative.vet_requires
    assert_equal %w[discover threat_model plan], iterative.optional
    assert_equal "gated", plane.track_forced_by_risk("high")
    assert_nil plane.track_forced_by_risk("low")
  end

  def test_a_control_plane_without_tracks_has_an_implicit_gated_track
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/workflow.yml")
      wf = YAML.safe_load_file(path)
      wf.delete("tracks")
      File.write(path, YAML.dump(wf))
      plane = SoftFoundry::ControlPlane.new(dir)
      assert_equal ["gated"], plane.track_names
      assert_equal "gated", plane.default_track
      assert_empty SoftFoundry::Check.new(plane).run.map(&:message)
      record = SoftFoundry::ChangeRecord.create(dir, "c", control_plane: plane)
      assert_equal "gated", record.track
      assert_equal "intake", record.metadata["status"]
    end
  end

  def test_hardening_phases_start_at_implement
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    refute plane.hardening_phase?(plane.phase("specify"))
    assert plane.hardening_phase?(plane.phase("implement"))
    assert plane.hardening_phase?(plane.phase("learn"))
  end

  # --- check ---------------------------------------------------------------

  def test_check_reports_an_undefined_default_track_and_unknown_phases
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/workflow.yml")
      wf = YAML.safe_load_file(path)
      wf["tracks"]["default"] = "casual"
      wf["tracks"]["forced_by_risk"]["high"] = "nowhere"
      wf["tracks"]["iterative"]["optional"] << "polish"
      File.write(path, YAML.dump(wf))
      messages = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run.map(&:message)
      assert messages.any? { |m| m.include?("default 'casual'") }, messages.inspect
      assert messages.any? { |m| m.include?("forced_by_risk high") && m.include?("nowhere") }, messages.inspect
      assert messages.any? { |m| m.include?("unknown phase 'polish'") }, messages.inspect
    end
  end

  # The exploring stage produces no evidence, so its skill may not be able
  # to write any commit-bound phase's directory.
  def test_check_refuses_an_exploring_skill_that_can_write_evidence
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/skills/exploration/permissions.yml")
      perms = YAML.safe_load_file(path)
      perms["write"] << "changes/${CHANGE}/06-verification/**"
      File.write(path, YAML.dump(perms))
      messages = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run.map(&:message)
      assert messages.any? { |m| m.include?("exploration") && m.include?("commit-bound evidence") && m.include?("06-verification") }, messages.inspect
    end
  end

  def test_check_requires_the_exploring_skill_contract
    with_fixture_repo do |dir|
      File.delete(File.join(dir, ".ai/skills/exploration/SKILL.md"))
      messages = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run.map(&:message)
      assert messages.any? { |m| m.include?("skill exploration: SKILL.md is missing") }, messages.inspect
    end
  end

  # --- change new ----------------------------------------------------------

  def test_new_on_the_iterative_track_starts_exploring_with_a_journal
    with_exploring_change do |_dir, _plane, record|
      assert_equal "iterative", record.track
      assert_equal "exploring", record.metadata["status"]
      assert_equal "implement", record.metadata["current_phase"]
      assert record.exploring?
      assert File.file?(record.iterations_path)
      assert_empty record.iterations
      assert_nil record.vetted
    end
  end

  def test_new_defaults_to_the_gated_track_with_no_exploration_directory
    with_fixture_repo do |dir|
      code, out = cli(dir, "change", "new", "g1")
      assert_equal 0, code, out
      assert_includes out, "track: gated"
      record = SoftFoundry::ChangeRecord.new(dir, "g1", control_plane: SoftFoundry::ControlPlane.new(dir))
      assert_equal "gated", record.track
      assert_equal "intake", record.metadata["status"]
      refute record.exploring?
      refute File.exist?(File.join(record.dir, "exploration"))
    end
  end

  def test_new_refuses_an_unknown_track
    with_fixture_repo do |dir|
      code, out = cli(dir, "change", "new", "g1", "--track", "casual")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "unknown track 'casual'"
      refute File.exist?(File.join(dir, "changes", "g1"))
      assert_raises(ArgumentError) { SoftFoundry::ChangeRecord.create(dir, "g2", control_plane: SoftFoundry::ControlPlane.new(dir), track: "casual") }
    end
  end

  # --- exploring -----------------------------------------------------------

  def test_ci_passes_and_status_describes_an_exploring_change
    with_exploring_change do |dir, _plane, record|
      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      journal(record, [{ "at" => "t", "asked" => "a", "changed" => "b", "deployed" => { "environment" => "development" } }])
      code, out = cli(dir, "change", "status")
      assert_equal 0, code, out
      assert_includes out, "track: iterative (exploring; 1 iteration recorded, last deployed to development"
    end
  end

  def test_no_hardening_phase_may_be_complete_while_exploring
    with_exploring_change do |dir, _plane, record|
      make_vettable!(dir, record)
      complete_phase!(record, "implement", sha: head(dir))
      complete_phase!(record, "verify", sha: head(dir))
      gate = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
      %w[implement verify].each do |id|
        result = gate.evaluate(id)
        assert result.failed?, id
        check = result.checks.find { |c| c.name == "not exploring" }
        assert_equal :fail, check.outcome
        assert_includes check.detail, "change vet"
      end
      refute gate.evaluate("specify").failed?, "phases before implement are allowed to complete while exploring"
      code, out = cli(dir, "ci")
      assert_equal 2, code, out
    end
  end

  def test_risk_high_forces_the_gated_track
    with_exploring_change do |dir, _plane, record|
      make_vettable!(dir, record, risk: "high")
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("intake")
      check = result.checks.find { |c| c.name == "track permitted" }
      assert_equal :fail, check.outcome
      assert_includes check.detail, "risk high forces the gated track"
      code, out = cli(dir, "change", "vet", "it1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "risk high forces the gated track"
    end
  end

  def test_exploring_status_on_a_track_without_an_exploring_stage_is_reported
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "g1")
      record = SoftFoundry::ChangeRecord.new(dir, "g1", control_plane: SoftFoundry::ControlPlane.new(dir))
      edit_metadata(dir, record) { |m| m.sub(/^status: intake.*$/, "status: exploring") }
      complete_phase!(record, "intake", sha: head(dir))
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("intake")
      check = result.checks.find { |c| c.name == "track permitted" }
      assert_equal :fail, check.outcome
      assert_includes check.detail, "no exploring stage"
    end
  end

  # --- change vet ----------------------------------------------------------

  def test_vet_refuses_until_the_exploring_stage_has_actually_happened
    with_exploring_change do |dir, _plane, _record|
      code, out = cli(dir, "change", "vet", "it1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "cannot vet"
      assert_includes out, "risk is not classified"
      assert_includes out, "records no iteration"
      assert_includes out, "00-intake is pending"
      assert_includes out, "02-specification is pending"
      assert_equal 4, fail_names(out).size, out
    end
  end

  def test_vet_refuses_a_specification_with_placeholders_or_uncommitted_edits
    with_exploring_change do |dir, _plane, record|
      make_vettable!(dir, record)
      File.write(File.join(record.dir, "02-specification", "specification.md"), "# Spec\n\nTBD\n")
      code, out = cli(dir, "change", "vet", "it1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "02-specification gate fails: no placeholders"
      assert_includes out, "02-specification has uncommitted changes"
      assert record.exploring?, "a refused vet changes nothing"
    end
  end

  def test_vet_records_the_person_and_commit_and_makes_hardening_phases_apply
    with_exploring_change do |dir, plane, record|
      make_vettable!(dir, record)
      code, out = cli(dir, "change", "vet", "it1", "--by", "A Person")
      assert_equal 0, code, out
      assert_includes out, "vetted by A Person at #{head(dir)[0, 12]}"
      refute record.exploring?
      assert_equal "in_progress", record.metadata["status"]
      assert_equal({ "by" => "A Person", "commit" => head(dir) }, record.vetted.slice("by", "commit"))
      assert record.vetted["at"]

      # implement's gate now passes: discover/threat_model/plan are not
      # required by the track, so the predecessor resolves to specify.
      complete_phase!(record, "implement", sha: head(dir))
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("implement")
      refute result.failed?, result.checks.map { |c| "#{c.name}: #{c.detail}" }.join("\n")
      assert_equal "02-specification", result.checks.find { |c| c.name == "predecessor complete" }.detail
      assert_nil plane.phase("discover").after
    end
  end

  def test_vet_defaults_the_person_to_the_git_identity
    with_exploring_change do |dir, _plane, record|
      make_vettable!(dir, record)
      code, out = cli(dir, "change", "vet", "it1")
      assert_equal 0, code, out
      assert_equal "Test", record.vetted["by"]
    end
  end

  def test_vet_is_only_for_an_exploring_change_on_an_exploring_track
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "g1")
      code, out = cli(dir, "change", "vet", "g1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "no exploring stage"
    end
    with_exploring_change do |dir, _plane, record|
      make_vettable!(dir, record)
      assert_equal 0, cli(dir, "change", "vet", "it1").first
      code, out = cli(dir, "change", "vet", "it1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "is not exploring"
    end
  end

  # --- specification lock --------------------------------------------------

  def test_the_specification_is_locked_at_the_vetted_commit
    with_exploring_change do |dir, _plane, record|
      make_vettable!(dir, record)
      assert_equal 0, cli(dir, "change", "vet", "it1").first
      gate = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
      lock = gate.evaluate("specify").checks.find { |c| c.name == "specification locked" }
      assert_equal :pass, lock.outcome

      File.write(File.join(record.dir, "02-specification", "acceptance-criteria.yml"), "criteria: []\n")
      result = gate.evaluate("specify")
      assert result.failed?
      lock = result.checks.find { |c| c.name == "specification locked" }
      assert_equal :fail, lock.outcome
      assert_includes lock.detail, "acceptance-criteria.yml"
      assert_includes lock.detail, "change reopen"

      # A committed edit is just as locked as an uncommitted one.
      commit_all(dir, "rewrite criteria")
      assert_equal :fail, gate.evaluate("specify").checks.find { |c| c.name == "specification locked" }.outcome
    end
  end

  def test_the_gated_track_has_no_specification_lock_check
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "g1")
      record = SoftFoundry::ChangeRecord.new(dir, "g1", control_plane: SoftFoundry::ControlPlane.new(dir))
      complete_phase!(record, "intake", sha: head(dir))
      complete_phase!(record, "discover", sha: head(dir))
      complete_phase!(record, "specify", sha: head(dir))
      names = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("specify").checks.map(&:name)
      refute_includes names, "specification locked"
    end
  end

  # --- change reopen -------------------------------------------------------

  def test_reopen_returns_to_exploring_and_resets_hardening_phases_keeping_their_files
    with_exploring_change do |dir, plane, record|
      make_vettable!(dir, record)
      assert_equal 0, cli(dir, "change", "vet", "it1").first
      vetted_at = record.vetted["commit"]
      complete_phase!(record, "implement", sha: head(dir))
      complete_phase!(record, "verify", sha: head(dir))
      log = File.join(record.dir, "05-implementation", "log.md")
      File.write(log, "# Implementation Log\n\nreal work\n")

      code, out = cli(dir, "change", "reopen", "it1", "--reason", "the person wants a different shape")
      assert_equal 0, code, out
      assert_includes out, "reset to pending, outputs kept: 05-implementation, 06-verification"
      assert record.exploring?
      assert_nil record.vetted
      assert_equal [{ "from_commit" => vetted_at, "reason" => "the person wants a different shape" }],
                   record.metadata["reopenings"].map { |r| r.slice("from_commit", "reason") }
      %w[implement verify].each do |id|
        h = record.handoff(plane.phase(id))
        assert_equal "pending", h["status"]
        assert_nil h["commit_sha"]
        assert_includes h["notes"], "reopened"
      end
      assert_equal "complete", record.phase_status(plane.phase("specify")), "phases before implement are untouched"
      assert_includes File.read(log), "real work"
      assert_equal 0, cli(dir, "ci").first, "a reopened change passes ci again"
    end
  end

  def test_reopen_requires_a_reason_and_an_exploring_track_and_refuses_closed
    with_exploring_change do |dir, _plane, record|
      code, out = cli(dir, "change", "reopen", "it1")
      refute_equal 0, code
      assert_includes out, "--reason is required"
      code, out = cli(dir, "change", "reopen", "it1", "--reason", "x")
      assert_equal 0, code
      assert_includes out, "already exploring"
      edit_metadata(dir, record) { |m| m.sub(/^status: exploring.*$/, "status: closed") }
      code, out = cli(dir, "change", "reopen", "it1", "--reason", "x")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "is closed"
    end
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "g1")
      code, out = cli(dir, "change", "reopen", "g1", "--reason", "x")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_includes out, "no exploring stage"
    end
  end

  # --- lifecycle end and close ---------------------------------------------

  # Track-optional phases count as legitimately pending, so an iterative
  # change reaches the end of its lifecycle without discover, threat_model,
  # or plan and without a skipped_phases rationale for each.
  def test_an_iterative_change_reaches_lifecycle_end_without_track_optional_phases
    with_exploring_change do |dir, _plane, record|
      make_vettable!(dir, record)
      assert_equal 0, cli(dir, "change", "vet", "it1").first
      commit_all(dir, "vetted")
      sha = head(dir)
      %w[implement verify evaluate attack review judge learn].each { |id| complete_phase!(record, id, sha: sha) }
      assert record.reached_lifecycle_end?
      assert_equal sha, record.finished_commit_sha
      commit_all(dir, "hardened")
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/it1", "-m", "merge it1")
      code, out = cli(dir, "change", "close", "it1")
      assert_equal 0, code, out
      assert_equal "closed", record.metadata["status"]
    end
  end

  # --- advisory ------------------------------------------------------------

  def test_iterative_track_without_a_recorded_development_environment_is_advised
    with_exploring_change do |dir, _plane, record|
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "environment" }
      assert_empty notices, "this repository's profile records a development environment"

      repo = File.join(dir, ".ai", "repository.yml")
      profile = YAML.safe_load_file(repo)
      profile.delete("environments")
      File.write(repo, YAML.dump(profile))
      record = SoftFoundry::ChangeRecord.new(dir, "it1", control_plane: SoftFoundry::ControlPlane.new(dir))
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "environment" }
      assert_equal 1, notices.size
      assert_includes notices.first.message, "records none under environments:"

      profile["environments"] = { "development" => { "status" => "NOT_APPLICABLE", "rationale" => "library" } }
      File.write(repo, YAML.dump(profile))
      record = SoftFoundry::ChangeRecord.new(dir, "it1", control_plane: SoftFoundry::ControlPlane.new(dir))
      assert_empty SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "environment" }
    end
  end

  def test_gated_track_never_gets_the_environment_advisory
    with_fixture_repo do |dir|
      repo = File.join(dir, ".ai", "repository.yml")
      profile = YAML.safe_load_file(repo)
      profile.delete("environments")
      File.write(repo, YAML.dump(profile))
      cli(dir, "change", "new", "g1")
      record = SoftFoundry::ChangeRecord.new(dir, "g1", control_plane: SoftFoundry::ControlPlane.new(dir))
      assert_empty SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "environment" }
    end
  end
end
