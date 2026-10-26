require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
class D
  include FinishedFixture
  def run(dir, env, *args)
    o, e, s = Open3.capture3({"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}.merge(env), "/tmp/sfbin/sf", *args, chdir: dir)
    $log << "$ sf #{args.map{|a| a.length>80 ? a[0,80]+'...' : a}.map(&:inspect).join(' ')}\nexit=#{s.exitstatus}\n#{o}#{e}\n"
    [s.exitstatus, o+e]
  end
  def go
    $log = +""
    with_finished_record("c1", undischarged: ["UND-1"]) do |dir, record|
      $log << "## bidi in --reason\n"
      run(dir,{}, "phase","reopen","verify","--reason","safe\u202Eevil\u200Bx\u2028y")
      $log << `grep -n "reason" #{dir}/changes/c1/metadata.yml | cat -v`
      run(dir,{}, "scan")
      run(dir,{}, "check")
      run(dir,{}, "change","status","c1")
    end
    File.write("/tmp/sfa-ev/drive2.txt", $log)
  end
end
D.new.go
