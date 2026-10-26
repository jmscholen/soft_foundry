require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
class D
  include FinishedFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def run(dir,*args); o,e,s = Open3.capture3(E,"/tmp/sfbin/sf",*args,chdir: dir); $log << "$ sf #{args.map(&:inspect).join(' ')}\nexit=#{s.exitstatus}\n#{(o+e).lines.reject{|l| l=~/^\s+✓|advisory|! warn/}.join[0,1500]}\n"; end
  def go
    $log = +"## ATTACK-RACE repro: release and phase reopen started together on a finished record\n"
    with_finished_record("c1") do |dir, record|
      ths = [["change","release","c1","--item","A=a"],["phase","reopen","verify","--reason","race"]].map { |a| Thread.new { o,e,s = Open3.capture3(E,"/tmp/sfbin/sf",*a,chdir: dir); $log << "[concurrent] sf #{a.first(2).join(' ')} -> exit #{s.exitstatus}\n" } }
      ths.each(&:join)
      run(dir,"change","status","c1")
      run(dir,"check"); run(dir,"ci")
      run(dir,"change","discharge","A","--note","done")
      run(dir,"phase","reopen","verify","--reason","fix the race")
    end
    File.write("/tmp/sfa-ev/drive7.txt", $log)
  end
end
D.new.go
