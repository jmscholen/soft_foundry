require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
class D
  include FinishedFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def run(dir, *args)
    o,e,s = Open3.capture3(E,"/tmp/sfbin/sf",*args,chdir: dir)
    $log << "$ sf #{args.map{|a| a.length>60 ? a[0,60]+'..' : a}.map(&:dump).join(' ')}\nexit=#{s.exitstatus}\n#{(o+e).lines.reject{|l| l=~/advisory|! warn|^\s+✓/}.join.scrub[0,500].dump.gsub('\n',"\n")}\n"
  end
  def go
    $log = +"## ATTACK-BIDI: bidi/zero-width text accepted by --reason, then every reset phase fails its 'content clean' gate once redone\n"
    with_finished_record("c1") do |dir, record|
      run(dir, "phase","reopen","verify","--reason","looks fine\u202E gnirts\u200B")
      commit_all(dir, "reopened")
      complete_phase!(record, "verify", sha: head(dir)); commit_all(dir,"redo")
      run(dir, "gate","verify")
    end
    File.write("/tmp/sfa-ev/drive11.txt", $log)
  end
end
D.new.go
