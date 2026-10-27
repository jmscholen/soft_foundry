# frozen_string_literal: true

require_relative "lifecycle_fixture"

# The access-control parity check: when the repository profile declares
# `access_control` and a changed path matches, verification must state the
# protection state of its checks. Structure only; the truth is review's.
class ProtectionStatedTest < Minitest::Test
  include LifecycleFixture

  CHECK = "protection stated"

  def declare_access_control!(dir, globs)
    path = File.join(dir, ".ai/repository.yml")
    data = YAML.safe_load_file(path) || {}
    data["access_control"] = globs
    File.write(path, YAML.dump(data))
  end

  def write_tests!(record, checks)
    phase = record.control_plane.phase("verify")
    File.write(File.join(record.phase_dir(phase), "tests.yml"), YAML.dump("size" => "full", "checks" => checks))
  end

  def a_check(extra = {}) = { "id" => "CHECK-001", "kind" => "tests", "command" => "run", "result" => "pass", "evidence" => "evidence/a", "criteria" => ["AC-001"] }.merge(extra)

  # plan complete, then a change to lib/auth.rb, then verify complete.
  def with_touched_record(globs: ["lib/auth*.rb"], touch: "lib/auth.rb")
    with_lifecycle_record(complete: %w[intake discover specify threat_model plan], current_phase: "verify") do |dir, record|
      declare_access_control!(dir, globs) if globs
      File.write(File.join(dir, touch), "x = 1\n")
      commit_all(dir, "implementation")
      yield dir, record
    end
  end

  def verify_gate(dir, record, checks)
    write_tests!(record, checks)
    complete_phase!(record, "verify", sha: head(dir))
    gate = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    gate.evaluate("verify").checks.find { |c| c.name == CHECK }
  end

  def test_fails_when_no_check_states_protection
    with_touched_record do |dir, record|
      check = verify_gate(dir, record, [a_check])
      assert_equal :fail, check.outcome
      assert_includes check.detail, "lib/auth.rb"
    end
  end

  def test_passes_with_one_check_in_force
    with_touched_record do |dir, record|
      assert_equal :pass, verify_gate(dir, record, [a_check("protection" => "in_force"), a_check("id" => "CHECK-002")]).outcome
    end
  end

  def test_passes_when_every_check_states_a_value_with_a_note
    with_touched_record do |dir, record|
      checks = [a_check("protection" => "disabled", "protection_note" => "fixture cannot sign requests"), a_check("id" => "CHECK-002", "protection" => "not_applicable", "protection_note" => "pure unit")]
      assert_equal :pass, verify_gate(dir, record, checks).outcome
    end
  end

  def test_disabled_without_a_note_fails_naming_the_check
    with_touched_record do |dir, record|
      check = verify_gate(dir, record, [a_check("protection" => "disabled")])
      assert_equal :fail, check.outcome
      assert_includes check.detail, "CHECK-001"
    end
  end

  def test_an_unknown_value_fails
    with_touched_record do |dir, record|
      assert_equal :fail, verify_gate(dir, record, [a_check("protection" => "mostly")]).outcome
    end
  end

  def test_not_applicable_without_a_declaration
    with_touched_record(globs: nil) do |dir, record|
      assert_equal :skip, verify_gate(dir, record, [a_check]).outcome
    end
  end

  def test_not_applicable_when_no_changed_path_matches
    with_touched_record(touch: "lib/other.rb") do |dir, record|
      assert_equal :skip, verify_gate(dir, record, [a_check]).outcome
    end
  end

  def test_an_invalid_glob_fails_rather_than_passing_silently
    with_touched_record(globs: ["lib/[auth"]) do |dir, record|
      check = verify_gate(dir, record, [a_check])
      assert_equal :fail, check.outcome
      assert_match(/access_control/, check.detail)
    end
  end

  def test_the_check_is_listed_only_for_the_verification_phase
    with_touched_record do |_dir, record|
      plane = record.control_plane
      assert_includes SoftFoundry::Gate.checks_for(plane, plane.phase("verify")), CHECK
      refute_includes SoftFoundry::Gate.checks_for(plane, plane.phase("plan")), CHECK
      assert SoftFoundry::Gate::CHECKS.key?(CHECK)
    end
  end
end
