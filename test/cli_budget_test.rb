# frozen_string_literal: true

require_relative "test_helper"

# Billing-aware budget behavior at the CLI: no budget on a subscription,
# a notice plus periodic warnings when usage is metered by an API key.
class CLIBudgetBillingTest < Minitest::Test
  include FoundryFixture

  KEYS = %w[ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX OPENAI_API_KEY XAI_API_KEY OPENROUTER_API_KEY SOFT_FOUNDRY_BILLING].freeze

  def subscription_env(overrides = {}) = KEYS.to_h { |k| [k, nil] }.merge(overrides)
  def api_env = subscription_env("ANTHROPIC_API_KEY" => "sk-test")

  def cli_env(dir, env, *args, **kw)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env(env) { code = SoftFoundry::CLI.new(args, out: out, err: err, root: dir, **kw).run }
    [code, out.string + err.string]
  end

  def record(dir, slug, usd)
    cli_env(dir, api_env, "budget", "record", "--change", slug, "--phase", "05-implementation", "--provider", "anthropic", "--model", "m", "--tokens-in", "1", "--tokens-out", "1", "--usd", usd.to_s)
  end

  def set_risk(dir, slug, risk)
    path = File.join(dir, "changes", slug, "metadata.yml")
    d = YAML.safe_load_file(path, permitted_classes: [Time, Date])
    d["risk"] = risk
    File.write(path, YAML.dump(d))
  end

  def test_status_on_a_subscription_shows_no_budget_and_never_exits_non_zero
    with_fixture_repo do |dir|
      cli_env(dir, subscription_env, "change", "new", "s1", "--title", "x")
      set_risk(dir, "s1", "low")
      record(dir, "s1", 999.0)
      code, out = cli_env(dir, subscription_env, "budget", "status", "--change", "s1")
      assert_equal 0, code, out
      assert_includes out, "billing: subscription"
      assert_includes out, "not applicable on a subscription"
      assert_includes out, "$999.00"
      refute_includes out, "OVER CAP"
      refute_includes out, "cap (max_usd_per_change)"
    end
  end

  def test_status_with_an_api_key_applies_the_policy
    with_fixture_repo do |dir|
      cli_env(dir, api_env, "change", "new", "a1", "--title", "x")
      set_risk(dir, "a1", "low")
      code, out = cli_env(dir, api_env, "budget", "status", "--change", "a1")
      assert_equal 0, code, out
      assert_includes out, "billing: api"
      assert_includes out, "ANTHROPIC_API_KEY"
      assert_includes out, "cap (max_usd_per_change): $10.00"
      assert_includes out, "warns every $10.00 of recorded spend (next warning at $10.00)"

      record(dir, "a1", 20.0)
      code, out = cli_env(dir, api_env, "budget", "status", "--change", "a1")
      assert_equal 2, code, out
      assert_includes out, "OVER CAP"
    end
  end

  def test_override_forces_subscription_even_with_a_key
    with_fixture_repo do |dir|
      cli_env(dir, api_env, "change", "new", "o1", "--title", "x")
      _, out = cli_env(dir, api_env.merge("SOFT_FOUNDRY_BILLING" => "subscription"), "budget", "status", "--change", "o1")
      assert_includes out, "billing: subscription (SOFT_FOUNDRY_BILLING=subscription)"
      code, out = cli_env(dir, api_env.merge("SOFT_FOUNDRY_BILLING" => "bogus"), "budget", "status", "--change", "o1")
      assert_equal 1, code
      assert_includes out, "SOFT_FOUNDRY_BILLING=bogus is not one of api, subscription"
    end
  end

  def test_record_warns_each_time_spend_passes_another_interval
    with_fixture_repo do |dir|
      cli_env(dir, api_env, "change", "new", "w1", "--title", "x")
      set_risk(dir, "w1", "high") # cap 150, approval 50: keep those out of the way
      code, out = record(dir, "w1", 4.0)
      assert_equal 0, code, out
      refute_includes out, "WARNING"

      code, out = record(dir, "w1", 5.5)
      assert_equal 0, code, out
      refute_includes out, "WARNING", "9.50 has not passed 10.00"

      code, out = record(dir, "w1", 0.85)
      assert_equal 0, code, out
      assert_includes out, "WARNING: recorded spend for w1 has passed $10.00 (now $10.35 of the $150.00 cap)"
      assert_includes out, "soft-foundry budget threshold"

      code, out = record(dir, "w1", 3.0)
      assert_equal 0, code, out
      refute_includes out, "WARNING", "still inside the 10-20 interval"

      code, out = record(dir, "w1", 12.0)
      assert_equal 0, code, out
      assert_includes out, "has passed $20.00 (now $25.35"
    end
  end

  def test_record_flags_the_approval_line_and_the_cap
    with_fixture_repo do |dir|
      cli_env(dir, api_env, "change", "new", "c1", "--title", "x")
      set_risk(dir, "c1", "medium") # cap 50, approval 20
      code, out = record(dir, "c1", 21.0)
      assert_equal 0, code, out
      assert_includes out, "HUMAN APPROVAL REQUIRED: recorded spend $21.00 is above $20.00"
      code, out = record(dir, "c1", 1.0)
      refute_includes out, "HUMAN APPROVAL REQUIRED", "only announced once, at the crossing"
      code, out = record(dir, "c1", 40.0)
      assert_equal 2, code, out
      assert_includes out, "recorded:"
      assert_includes out, "OVER CAP"
    end
  end

  def test_record_on_a_subscription_records_silently
    with_fixture_repo do |dir|
      cli_env(dir, subscription_env, "change", "new", "s2", "--title", "x")
      set_risk(dir, "s2", "low")
      code, out = cli_env(dir, subscription_env, "budget", "record", "--change", "s2", "--phase", "05-implementation", "--provider", "anthropic", "--model", "m", "--tokens-in", "1", "--tokens-out", "1", "--usd", "500")
      assert_equal 0, code, out
      assert_includes out, "recorded:"
      refute_includes out, "WARNING"
      refute_includes out, "OVER CAP"
    end
  end

  def test_threshold_command_shows_sets_disables_and_resets
    with_fixture_repo do |dir|
      code, out = cli_env(dir, api_env, "budget", "threshold")
      assert_equal 0, code, out
      assert_includes out, "warns every $10.00"
      assert_includes out, "source: .ai/policies/budget.yml"

      code, out = cli_env(dir, api_env, "budget", "threshold", "25")
      assert_equal 0, code, out
      assert_includes out, "warns every $25.00"
      assert_includes out, "source: .soft-foundry/budget.yml (machine-local, gitignored)"

      cli_env(dir, api_env, "change", "new", "t1", "--title", "x")
      set_risk(dir, "t1", "high")
      _, out = record(dir, "t1", 12.0)
      refute_includes out, "WARNING", "10 is no longer a boundary"
      _, out = record(dir, "t1", 14.0)
      assert_includes out, "has passed $25.00"

      code, out = cli_env(dir, api_env, "budget", "threshold", "off")
      assert_equal 0, code, out
      assert_includes out, "periodic warnings: off"
      _, out = record(dir, "t1", 30.0)
      refute_includes out, "WARNING"

      code, out = cli_env(dir, api_env, "budget", "threshold", "default")
      assert_equal 0, code, out
      assert_includes out, "warns every $10.00"
      assert_includes out, "source: .ai/policies/budget.yml"

      code, out = cli_env(dir, api_env, "budget", "threshold", "-5")
      assert_equal 1, code
      assert_includes out, "must be positive"
      code, out = cli_env(dir, api_env, "budget", "threshold", "lots")
      assert_equal 1, code
      assert_includes out, "expected a dollar amount"
    end
  end

  def test_change_new_prints_the_billing_notice
    with_fixture_repo do |dir|
      code, out = cli_env(dir, api_env, "change", "new", "n1", "--title", "x")
      assert_equal 0, code, out
      assert_includes out, "billing: API key (ANTHROPIC_API_KEY set"
      assert_includes out, "budget:  cap $50.00 per change (risk: unset); human approval required above $20.00"
      assert_includes out, "budget:  warns every $10.00"
      assert_includes out, "budget:  n1 recorded so far: $0.00"

      code, out = cli_env(dir, subscription_env, "change", "new", "n2", "--title", "x")
      assert_equal 0, code, out
      assert_includes out, "billing: subscription"
      assert_includes out, "no budget applies"
      refute_includes out, "budget:  cap"
    end
  end

  def test_shell_launch_is_preceded_by_a_shell_specific_notice
    with_fixture_repo do |dir|
      launched = nil
      fake = ->(name, args) { launched = [name, args] }
      # An OpenAI key in the environment is irrelevant to how `claude` bills.
      code, out = cli_env(dir, subscription_env("OPENAI_API_KEY" => "k"), "shell", "claude", "--resume", shell: fake)
      assert_equal 0, code, out
      assert_equal ["claude", ["--resume"]], launched
      assert_includes out, "billing: subscription (no ANTHROPIC_API_KEY in the environment, so claude bills to its own login); no budget applies"

      code, out = cli_env(dir, subscription_env("OPENAI_API_KEY" => "k"), "shell", "codex", shell: fake)
      assert_equal 0, code, out
      assert_includes out, "billing: API key (OPENAI_API_KEY set"
      assert_includes out, "budget:  no change record for this branch yet"
    end
  end

  def test_init_and_onboard_print_the_notice
    with_target_repo do |dir|
      code, out = init(dir, env: api_env)
      assert_equal 0, code, out
      assert_includes out, "billing: API key"
      assert_includes out, "budget:  cap $50.00 per change"
    end
  end
end
