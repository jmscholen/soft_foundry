require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
require "yaml"
class D
  include LifecycleFixture
  PRE = %w[intake discover specify threat_model plan implement verify]
  def envh(dir, env) = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil,"PATH"=>"/tmp/sfbin/stubs:#{ENV['PATH']}","STUB_LOG"=>"#{dir}/../stublog"}.merge(env)
  def run(dir, env, *args, mid: nil)
    o = e = s = nil; extra = ""
    t0 = Time.now
    Open3.popen3(envh(dir, env), "/tmp/sfbin/sf", *args, chdir: dir) do |i, so, se, th|
      extra = mid.call(th.pid) if mid
      o = so.read; e = se.read; s = th.value
    end
    $log << "$ #{env.reject{|k,_|k=="STUB_LOG"}.inspect} sf #{args.map(&:inspect).join(' ')}\nexit=#{s.exitstatus.inspect} sig=#{s.termsig.inspect} (#{(Time.now-t0).round(1)}s)\n#{o}#{e}#{extra}\n"
    [s.exitstatus, o+e]
  end
  def mk(complete: PRE, current_phase: "evaluate", status: "in_progress")
    with_lifecycle_record("c1", complete: complete, status: status, current_phase: current_phase) { |dir, record| yield dir, record }
  end
  def go
    $log = +""
    mk do |dir, record|
      $log << "## PAC-07 ps while running (runner title)\n"
      run(dir,{"STUB_SLEEP"=>"3"}, "phase","run","evaluate","attack","--parallel","--shell","claude","--env","DB_URL=postgres://u:secret@h/{phase}", mid: ->(pid){ sleep 1.2; "--ps (runner pid #{pid})--\n" + `ps -o pid,command -p #{pid}` })
    end
    mk do |dir, record|
      $log << "## PAC-10 session commits during parallel run\n"
      run(dir,{"STUB_COMMIT"=>"1"}, "phase","run","evaluate","attack","--parallel","--shell","claude","--env","A=1")
      $log << `cd #{dir} && git log --oneline | head -4`
      h = %w[07-evaluation 08-attack].map{|d| YAML.safe_load_file("#{dir}/changes/c1/#{d}/handoff.yml")["executed_by"].slice("exit_status")}
      $log << "executed_by after: #{h.inspect}\n"
    end
    mk do |dir, record|
      $log << "## PAC-11 stale auto-reopen\n"
      %w[evaluate attack].each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "evalattack")
      run(dir,{}, "phase","run","evaluate","--shell","claude","--dry-run")
      File.write("#{dir}/lib/app.rb", "puts 2\n"); commit_all(dir, "app change")
      run(dir,{}, "phase","run","evaluate","--shell","claude","--dry-run")
      run(dir,{"STUB_EXIT"=>"0"}, "phase","run","evaluate","--shell","claude")
      $log << `cd #{dir} && grep -n "phase_reopenings" -A14 changes/c1/metadata.yml`
      run(dir,{}, "phase","run","evaluate","--shell","claude")
    end
    mk(complete: PRE+%w[evaluate attack review judge learn], status: "released", current_phase: "learn") do |dir, record|
      $log << "## PAC-11 released/closed: auto-reopen resets nothing\n"
      File.write("#{dir}/lib/app.rb", "puts 3\n"); commit_all(dir, "app change")
      b = tree_bytes(dir)
      run(dir,{}, "phase","run","evaluate","--shell","claude")
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--shell","claude")
      $log << "unchanged: #{b == tree_bytes(dir)}\n"
    end
    mk do |dir, record|
      $log << "## PAC-13 reopen refusal statuses, specify reopen on complete record\n"
      %w[closed released exploring awaiting_human].each do |st|
        set_metadata!(record, status: st); commit_all(dir,"st #{st}")
        b = tree_bytes(dir)
        run(dir,{}, "phase","reopen","verify","--reason","r")
        $log << "unchanged: #{b == tree_bytes(dir)}\n"
      end
      set_metadata!(record, status: "in_progress"); commit_all(dir,"back")
      ev = tree_bytes(dir).reject{|k,_| k.end_with?("handoff.yml") || k.end_with?("metadata.yml")}
      run(dir,{}, "phase","reopen","specify","--reason","spec change")
      $log << "evidence files byte-identical after reopen: #{ev == tree_bytes(dir).reject{|k,_| k.end_with?("handoff.yml") || k.end_with?("metadata.yml")}}\n"
      run(dir,{}, "phase","reopen","specify","--reason","again")
      run(dir,{}, "phase","reopen","nonsense","--reason","x")
      run(dir,{}, "phase","reopen","specify")
    end
    File.write("/tmp/sfa-ev/drive5.txt", $log)
  end
end
D.new.go
