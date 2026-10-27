# frozen_string_literal: true

require_relative "test_helper"

# `check` lints isolated_phases in .ai/workflow.yml (REQ-009).
class CheckIsolatedPhasesTest < Minitest::Test
  include FoundryFixture

  def findings(dir) = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run

  def with_isolated(list)
    with_fixture_repo do |dir|
      wf = File.join(dir, ".ai", "workflow.yml")
      File.write(wf, File.read(wf).gsub(/^isolated_phases:.*\n/, "") + "\nisolated_phases: #{list}\n")
      yield dir
    end
  end

  def test_evaluate_and_attack_pass
    with_isolated("[evaluate, attack]") do |dir|
      assert_equal [], findings(dir).select { |f| f.level == :error }.map(&:message)
    end
  end

  def test_an_absent_list_is_valid
    with_fixture_repo do |dir|
      wf = File.join(dir, ".ai", "workflow.yml")
      File.write(wf, File.read(wf).gsub(/^isolated_phases:.*\n/, ""))
      assert_equal [], findings(dir).select { |f| f.level == :error && f.message.include?("isolated_phases") }
    end
  end

  def test_phases_that_write_code_or_judge_are_refused_naming_the_id
    %w[implement remediate review judge].each do |id|
      with_isolated("[evaluate, #{id}]") do |dir|
        errors = findings(dir).select { |f| f.level == :error && f.message.include?("isolated_phases") }
        assert errors.any? { |f| f.message.include?("'#{id}'") }, "#{id}: #{errors.map(&:message).inspect}"
      end
    end
  end

  def test_an_unknown_id_is_refused
    with_isolated("[evaluate, nonsense]") do |dir|
      assert findings(dir).any? { |f| f.level == :error && f.message.include?("'nonsense'") && f.message.include?("not a lifecycle phase") }
    end
  end

  def test_a_phase_whose_skill_can_write_application_code_is_refused
    with_isolated("[evaluate, attack]") do |dir|
      path = File.join(dir, ".ai", "skills", "evaluation", "permissions.yml")
      perms = YAML.safe_load_file(path)
      perms["write"] << "${APP}"
      File.write(path, YAML.dump(perms))
      assert findings(dir).any? { |f| f.level == :error && f.message.include?("'evaluate'") && f.message.include?("application") }
    end
  end

  def test_a_list_that_is_not_a_list_is_refused
    with_isolated("evaluate") do |dir|
      assert findings(dir).any? { |f| f.level == :error && f.message.include?("isolated_phases must be a list") }
    end
  end
end
