# frozen_string_literal: true

require_relative "lifecycle_fixture"

# The runner tells every session its own phase through SOFT_FOUNDRY_PHASE
# and passes the environment to the child process.
class PhaseRunMarkerTest < Minitest::Test
  include LifecycleFixture

  def test_a_single_phase_launch_carries_the_marker_and_no_parallel_flag
    with_lifecycle_record(complete: LIFECYCLE - %w[review judge], current_phase: "attack") do |dir, _record|
      launches = []
      code, out, err = run_cli(dir, "phase", "run", "review", "--shell", "claude", runner: ->(l) { launches << l; 0 })
      assert_equal 0, code, out + err
      assert_equal({ "SOFT_FOUNDRY_PHASE" => "review" }, launches.first.env)
    end
  end

  def test_launch_inspect_names_variables_but_never_values
    launch = SoftFoundry::PhaseRunner::Launch.new(shell: "claude", executable: "claude", args: [], prompt: "p", session_id: nil,
                                                  env: { "DATABASE_URL" => "postgres://user:s3cret@host/db" })
    refute_includes launch.inspect, "s3cret"
    assert_includes launch.inspect, "DATABASE_URL"
  end

  def test_a_launch_without_env_has_an_empty_one
    launch = SoftFoundry::PhaseRunner::Launch.new(shell: "claude", executable: "claude", args: [], prompt: "p", session_id: nil)
    assert_equal({}, launch.env)
  end

  def test_the_spawned_child_receives_the_environment
    Dir.mktmpdir do |bin|
      script = File.join(bin, "claude")
      File.write(script, "#!/bin/sh\nprintf '%s|%s' \"$SOFT_FOUNDRY_PHASE\" \"$EXTRA_VAR\" > \"$OUT_FILE\"\n")
      File.chmod(0o755, script)
      with_lifecycle_record(complete: LIFECYCLE - %w[review judge], current_phase: "attack") do |dir, _record|
        out_file = File.join(dir, "..", "marker-out-#{Process.pid}")
        path = "#{bin}:#{ENV['PATH']}"
        env = { "PATH" => path, "OUT_FILE" => out_file }
        code, out, err = run_cli(dir, "phase", "run", "review", "--shell", "claude", env: env)
        assert_equal 0, code, out + err
        assert_equal "review|", File.read(out_file)
      ensure
        File.delete(out_file) if out_file && File.exist?(out_file)
      end
    end
  end
end
