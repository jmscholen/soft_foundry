# frozen_string_literal: true

require_relative "test_helper"

class CheckTest < Minitest::Test
  include FoundryFixture

  def test_repository_control_plane_passes
    findings = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(REPO_ROOT)).run
    assert_empty findings.map(&:message)
  end

  def test_missing_template_is_reported
    with_fixture_repo do |dir|
      File.delete(File.join(dir, ".ai/skills/planning/template/rollback.md"))
      findings = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run
      assert findings.any? { |f| f.message.include?("planning") && f.message.include?("rollback.md") }
    end
  end

  def test_write_to_protected_policy_is_reported
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/skills/learning/permissions.yml")
      perms = YAML.safe_load_file(path)
      perms["write"] << ".ai/policies/**"
      File.write(path, YAML.dump(perms))
      findings = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run
      assert findings.any? { |f| f.message.include?("protected") }
    end
  end

  def test_unknown_path_group_is_reported
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/skills/intake/permissions.yml")
      perms = YAML.safe_load_file(path)
      perms["read"] << "${WIDGETS}"
      File.write(path, YAML.dump(perms))
      findings = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run
      assert findings.any? { |f| f.message.include?("${WIDGETS}") }
    end
  end

  def test_bad_transition_target_is_reported
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/workflow.yml")
      wf = YAML.safe_load_file(path)
      wf["transitions"]["judge"]["on_blocked"] = "nowhere"
      File.write(path, YAML.dump(wf))
      findings = SoftFoundry::Check.new(SoftFoundry::ControlPlane.new(dir)).run
      assert findings.any? { |f| f.message.include?("nowhere") }
    end
  end
end
