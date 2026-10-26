require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
class D
  include FinishedFixture
  def run(dir, env, *args, label:, log:)
    o, e, s = Open3.capture3({"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}.merge(env), "/tmp/sfbin/sf", *args, chdir: dir)
    log << "### #{label}\n$ #{env.map{|k,v|"#{k}=#{v.inspect}"}.join(' ')} sf #{args.map(&:inspect).join(' ')}\nexit=#{s.exitstatus}\n--stdout--\n#{o}--stderr--\n#{e}\n"
    [s.exitstatus, o, e]
  end
  def snap(dir) = tree_bytes(dir)
  def go
    log = +""
    with_finished_record("c1", undischarged: ["UND-1"]) do |dir, record|
      b0 = snap(dir)
      # PAC-01 marker refusals
      %w[implement review attack verify].each do |ph|
        run(dir, {"SOFT_FOUNDRY_PHASE"=>ph}, "phase","reopen","verify","--reason","x", label:"PAC-01 reopen marker=#{ph}", log: log)
        run(dir, {"SOFT_FOUNDRY_PHASE"=>ph}, "change","release","c1","--item","A=a", label:"PAC-01 release marker=#{ph}", log: log)
      end
      run(dir, {"SOFT_FOUNDRY_PHASE"=>""}, "phase","reopen","verify","--reason","x", label:"PAC-01 reopen marker empty", log: log)
      run(dir, {"SOFT_FOUNDRY_PHASE"=>""}, "change","release","c1","--item","A=a", label:"PAC-01 release marker empty", log: log)
      log << "tree unchanged after marker refusals: #{b0 == snap(dir)}\n"
      # PAC-06 injection on release
      payloads = {
        "newline"=>"a\nb: injected", "esc"=>"x\e[31mred", "nul"=>"x\0y", "colon"=>"k: v # c", "dashes"=>"---", "501"=>"a"*501, "500"=>"a"*500,
        "bidi"=>"safe\u202Eevil", "zwsp"=>"a\u200Bb", "c1"=>"a\u009Bb", "linesep"=>"a\u2028b", "nel"=>"a\u0085b", "tabs"=>"a\tb", "cr"=>"a\rb", "del"=>"a\x7Fb", "ansi8"=>"a\u009b31mb",
        "yaml-anchor"=>"&a *a !!ruby/object:Object {}", "pct"=>"%s %n {phase}", "html"=>"<script>alert(1)</script>"}
      payloads.each do |k, v|
        b = snap(dir)
        c,_,_ = run(dir, {}, "phase","reopen","verify","--reason",v, label:"PAC-06 reopen reason #{k}", log: log) rescue (log << "SPAWN ERR #{$!.message}\n"; next)
        log << "=> exit #{c}; record changed: #{b != snap(dir)}\n"
        # restore
        sh(dir,"git","checkout","-q","--","."); sh(dir,"git","clean","-fdq")
      end
    end
    File.write("/tmp/sfa-ev/drive1.txt", log)
  end
end
D.new.go
