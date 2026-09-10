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

  LEVELS_0_TO_4_CAPABILITIES = %w[
    repository.git_detected repository.agent_bootstrap repository.execution_path_known
    architecture.documented_or_discoverable coding_standards.defined technology.languages_detected
    technology.frameworks_detected infrastructure.detected_or_not_applicable testing.strategy_detected
    change.intake_required change.specification_required change.acceptance_criteria_required
    change.provenance_enabled change.acceptance_criteria_locking
    verification.automated_tests verification.gate evaluation.user_journey_gate
    evidence.commit_binding evidence.failed_results_retained
  ].freeze

  LEVEL_5_CAPABILITIES = %w[
    governance.risk_classification governance.skill_permissions governance.human_boundaries
    governance.separation_of_duties security.threat_modeling security.adversarial_validation
    observability.failure_detection observability.health_signal observability.operational_visibility
    observability.alerting observability.standard_dashboard judgment.final_gate
  ].freeze

  def passing_capabilities_through_level_5(overrides = {})
    (LEVELS_0_TO_4_CAPABILITIES + LEVEL_5_CAPABILITIES).each_with_object({}) do |cap, caps|
      caps[cap] = { "status" => overrides.fetch(cap, "PASS") }
    end
  end

  def test_missing_standard_dashboard_blocks_level_5_when_iac_is_present
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    caps = passing_capabilities_through_level_5("observability.standard_dashboard" => "MISSING")
    result = plane.score_maturity(caps)
    assert_equal 4, result["current_level"]
    assert(result["gaps"].any? { |g| g["capability"] == "observability.standard_dashboard" })
  end

  def test_standard_dashboard_not_applicable_when_no_iac_reaches_level_5
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    caps = passing_capabilities_through_level_5("observability.standard_dashboard" => "NOT_APPLICABLE")
    result = plane.score_maturity(caps)
    assert_equal 5, result["current_level"]
  end

  def test_standard_dashboard_pass_reaches_level_5
    plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
    caps = passing_capabilities_through_level_5
    result = plane.score_maturity(caps)
    assert_equal 5, result["current_level"]
    assert_equal "governed", result["current_id"]
  end
end
