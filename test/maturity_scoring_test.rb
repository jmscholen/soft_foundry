# frozen_string_literal: true

require_relative "test_helper"

class MaturityScoringTest < Minitest::Test
  include FoundryFixture

  def test_score_stops_at_the_first_unmet_level
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    caps = {
      "repository.git_detected" => { "status" => "PASS" },
      "repository.agent_bootstrap" => { "status" => "PASS" },
      "repository.execution_path_known" => { "status" => "PASS" },
      "architecture.documented_or_discoverable" => { "status" => "UNKNOWN" }
    }
    result = plane.score_maturity(caps)
    assert_equal 1, result["current_level"]
    assert_equal "agent_accessible", result["current_id"]
    refute_empty result["gaps"]
    assert(result["gaps"].any? { |g| g["capability"] == "architecture.documented_or_discoverable" })
  end

  def test_score_zero_when_nothing_satisfied
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    result = plane.score_maturity({})
    assert_equal 0, result["current_level"]
    assert_equal "unknown", result["current_id"]
  end

  def test_external_and_not_applicable_count_as_satisfied
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    caps = {
      "repository.git_detected" => { "status" => "EXTERNAL" },
      "repository.agent_bootstrap" => { "status" => "NOT_APPLICABLE" },
      "repository.execution_path_known" => { "status" => "PASS" }
    }
    result = plane.score_maturity(caps)
    assert_equal 1, result["current_level"]
  end
end
