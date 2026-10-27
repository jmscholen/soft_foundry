require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
require "yaml"
# ATTACK-018: kill a phase reopen between its renames; then check/ci/close/gate/rerun
class D
  include FinishedFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def run(dir, *args, env: {})
    o,e,s = Open3.capture3(E.merge(env),"/tmp/sfbin/sf",*args,chdir: dir)
    keep = (o+e).lines.reject{|l| l=~/^\s*✓ pass eval|advisory/}.join.scrub[0,400]
    $log << "$ #{env.empty? ? '' : env.inspect+' '}sf #{args.map(&:inspect).join(' ')}\nexit=#{s.exitstatus} signal=#{s.termsig.inspect}\n#{keep}\n"
    s.exitstatus
  end
  def state(dir)
    meta = YAML.safe_load_file("#{dir}/changes/c1/metadata.yml", permitted_classes: [Time, Date])
    hs = %w[06-verification 07-evaluation 08-attack 13-review 14-judgment 15-learning].map { |d| YAML.safe_load_file("#{dir}/changes/c1/#{d}/handoff.yml")["status"] }
    left = Dir.glob("#{dir}/changes/c1/**/*.soft-foundry-tmp").map { |f| f.sub(dir+"/","") }
    $log << "STATE status=#{meta['status']} reopenings=#{Array(meta['phase_reopenings']).size} handoffs(verify..learn)=#{hs.inspect} leftover_tmp=#{left.size}\n"
  end
  def go
    $log = +""
    hook = File.expand_path("kill_hook.rb", __dir__)
    [1, 2, 3, 6, 7].each do |k|
      with_finished_record("c1") do |dir, record|
        $log << "### reopen verify killed before rename ##{k}\n"
        state(dir)
        run(dir, "phase","reopen","verify","--reason","kill test #{k}", env: {"KILL_AT"=>k.to_s, "RUBYOPT"=>"-I/tmp/sfa/lib -r#{hook}"})
        state(dir)
        run(dir, "check"); run(dir, "ci"); run(dir, "change","status","c1"); run(dir, "change","close","c1")
        run(dir, "gate","judge")
        $log << "-- retry after kill (leftover temps present?)\n"
        run(dir, "phase","reopen","verify","--reason","retry #{k}")
        state(dir)
        run(dir, "change","close","c1")
      end
    end
    File.write("/tmp/sfa-ev/drive14.txt", $log)
  end
end
D.new.go
