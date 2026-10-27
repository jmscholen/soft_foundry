require_relative "/tmp/atk2/repo/test/lifecycle_fixture"
load "/tmp/atk2/repo/test/phase_run_parallel_test.rb"
class ParallelEdge < PhaseRunParallelTest
  def test_session_declared_blocked
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        id = phase_of(launch); complete!(record, dir, id)
        if id == "attack"
          path = record.handoff_path(record.control_plane.phase("attack"))
          h = YAML.safe_load_file(path); File.write(path, YAML.dump(h.merge("status" => "blocked", "blocking" => ["x"])))
        end
        0
      end
      puts "EDGE session-declared blocked: exit=#{code}"; puts out.lines.grep(/phase |parallel:|blocked/)
    end
  end
  def test_blocked_and_failed_session
    with_parallel_record do |dir, record|
      code, out, = run_parallel(dir, "evaluate", "attack", "--parallel", "--shell", "claude") do |launch|
        id = phase_of(launch); complete!(record, dir, id)
        if id == "evaluate"
          path = record.handoff_path(record.control_plane.phase("evaluate"))
          h = YAML.safe_load_file(path); File.write(path, YAML.dump(h.merge("blocking" => ["n"])))
        end
        id == "attack" ? 1 : 0
      end
      puts "EDGE blocked+nonzero session: exit=#{code}"
    end
  end
end
