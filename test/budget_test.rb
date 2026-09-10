# frozen_string_literal: true

require_relative "test_helper"

class BudgetTest < Minitest::Test
  include FoundryFixture

  def test_new_change_starts_with_an_empty_ledger
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "b1", control_plane: plane)
      b = SoftFoundry::Budget.new(record)
      assert_empty b.entries
      t = b.totals
      assert_equal 0, t.tokens_in
      assert_nil t.estimated_usd
    end
  end

  def test_record_and_sum_multiple_entries
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "b2", control_plane: plane)
      b = SoftFoundry::Budget.new(record)
      b.record!(phase: "00-intake", provider: "anthropic", model: "claude-sonnet-5", tokens_in: 1000, tokens_out: 200, estimated_usd: 0.10)
      b.record!(phase: "05-implementation", provider: "openrouter", model: "some/model", tokens_in: 5000, tokens_out: 1000, estimated_usd: nil)
      t = SoftFoundry::Budget.new(record).totals
      assert_equal 6000, t.tokens_in
      assert_equal 1200, t.tokens_out
      assert_in_delta 0.10, t.estimated_usd
      assert_equal 1, t.entries_missing_cost
      assert_equal 2, SoftFoundry::Budget.new(record).entries.size
    end
  end

  def test_policy_resolves_by_risk_and_over_cap_detection
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "b3", control_plane: plane)
      low = SoftFoundry::Budget.policy(plane, risk: "low")
      high = SoftFoundry::Budget.policy(plane, risk: "high")
      unset = SoftFoundry::Budget.policy(plane, risk: nil)
      assert_equal 10.00, low.max_usd_per_change
      assert_equal 150.00, high.max_usd_per_change
      assert_equal 50.00, unset.max_usd_per_change

      b = SoftFoundry::Budget.new(record)
      refute b.over_cap?(low)
      b.record!(phase: "05-implementation", provider: "anthropic", model: "m", tokens_in: 1, tokens_out: 1, estimated_usd: 20.00)
      assert b.over_cap?(low)
      refute b.over_cap?(high)
    end
  end
end
