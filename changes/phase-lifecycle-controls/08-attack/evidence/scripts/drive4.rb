require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
class D
  include LifecycleFixture
  PRE = %w[intake discover specify threat_model plan implement verify]
  def run(dir, env, *args, sleepps: false)
    envh = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil,"PATH"=>"/tmp/sfbin/stubs:#{ENV['PATH']}","STUB_LOG"=>"#{dir}/../stublog"}.merge(env)
    o = e = s = nil
    ps = ""
    t0 = Time.now
    Open3.popen3(envh, "/tmp/sfbin/sf", *args, chdir: dir) do |i, so, se, th|
      if sleepps
        sleep 1.5
        ps = `ps -axo pid,command | grep -v grep | grep -E "soft-foundry|sf phase|claude" | cut -c1-300`
        ps2 = `ps -axeww -o pid,command | grep -v grep | grep "stubs/claude" | head -2 | cut -c1-200`
      end
      o = so.read; e = se.read; s = th.value
    end
    $log << "$ #{env.reject{|k,_|k=="STUB_LOG"}.inspect} sf #{args.map(&:inspect).join(' ')}\nexit=#{s.exitstatus} (#{(Time.now-t0).round(1)}s)\n#{o}#{e}#{ps.empty? ? '' : "--ps while running--\n#{ps}"}\n"
    [s.exitstatus, o+e]
  end
  def mk(complete: PRE, current_phase: "evaluate")
    with_lifecycle_record("c1", complete: complete, status: "in_progress", current_phase: current_phase) { |dir, record| yield dir, record }
  end
  def go
    $log = +""
    mk do |dir, record|
      $log << "## PAC-09 parallel refusals\n"
      before = tree_bytes(dir)
      [%w[implement review], %w[evaluate evaluate], %w[Evaluate Attack], %w[judge attack], %w[evaluate], %w[evaluate attack remediate], %w[verify attack], ["evaluate","../attack"], ["evaluate","attack\n"]].each do |names|
        run(dir,{}, "phase","run",*names,"--parallel","--shell","claude")
      end
      $log << "tree unchanged after parallel refusals: #{before == tree_bytes(dir)}\n"
      $log << "## PAC-07 env secrets (dry-run & refusals)\n"
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--dry-run","--env","DB_URL=postgres://u:secret@h/{phase}")
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--env","SOFT_FOUNDRY_PHASE=review","--dry-run")
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--env","lower=secretval","--dry-run")
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--env","1A=secretval","--dry-run")
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--env","postgres://u:secretpw@h/db?x=1","--dry-run")
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--env","DB_URL=sec\0ret","--dry-run") rescue $log << "spawn NUL err #{$!.class}\n"
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--env=DB_URL=secretinline","--dry-run")
      run(dir,{}, "phase","run","evaluate","--env=DB_URL=secretinline2","--dry-run")
      run(dir,{}, "phase","run","evaluate","--env","DB_URL=postgres://u:secret@h/{phase}","--dry-run")
      run(dir,{}, "phase","run","evaluate","attack","--parallel","--env","A=1","--env","A=2","--dry-run")
      $log << "## PAC-07/10 real parallel run with stub, secret env, commit during run\n"
      run(dir,{"STUB_SLEEP"=>"4"}, "phase","run","evaluate","attack","--parallel","--shell","claude","--env","DB_URL=postgres://u:secret@h/{phase}","--env","SECRET_TOKEN=tok-abc123", sleepps: true)
      $log << `grep -rn "secret\\|tok-abc123" #{dir}/changes #{dir}/.soft-foundry 2>/dev/null | head`
      $log << "grep for secret in record: done\n"
      $log << "stub envs:\n" + Dir["#{dir}/../stublog/*.txt"].map{|f| "-- #{File.basename(f)}\n#{File.read(f)}"}.join
      $log << "status after:\n" + `cd #{dir} && git status --short | head` 
    end
    File.write("/tmp/sfa-ev/drive4.txt", $log)
  end
end
D.new.go
