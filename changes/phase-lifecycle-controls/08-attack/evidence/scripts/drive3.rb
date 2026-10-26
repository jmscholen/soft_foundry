require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
class D
  include FinishedFixture
  def run(dir, env, *args)
    o, e, s = Open3.capture3({"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}.merge(env), "/tmp/sfbin/sf", *args, chdir: dir)
    $log << "$ #{env.empty? ? '' : env.inspect+' '}sf #{args.map{|a| a.length>80 ? a[0,80]+'...' : a}.map(&:inspect).join(' ')}\nexit=#{s.exitstatus}\n#{o}#{e}\n"
    [s.exitstatus, o+e]
  end
  def go
    $log = +""
    # PAC-03/04: forged finished record (all handoffs hand-written complete with placeholder 'done' text), judgment undischarged
    with_finished_record("c1", undischarged: ["UND-1","UND-2"], merge: false) do |dir, record|
      $log << "## PAC-03 forged record: handoffs hand-edited complete, no executed_by, no real evidence\n"
      run(dir,{}, "change","release","c1","--item","THROWAWAY=nothing really")
      $log << `grep -n "release" -A25 #{dir}/changes/c1/metadata.yml`
      run(dir,{}, "change","status","c1")
      $log << "## PAC-04 close refuses until discharged\n"
      run(dir,{}, "change","close","c1")
      run(dir,{}, "change","discharge","UND-1","--note","ok")
      run(dir,{}, "change","discharge","UND-1","--note","again")
      run(dir,{}, "change","discharge","NOPE","--note","x")
      run(dir,{}, "change","discharge","THROWAWAY","--note","x\ny")
      run(dir,{}, "change","discharge","THROWAWAY","--note","<script>alert(1)</script>")
      run(dir,{"SOFT_FOUNDRY_PHASE"=>"review"}, "change","discharge","UND-2","--note","x")
      run(dir,{}, "change","release","c1","--item","Z=z")
      run(dir,{}, "phase","reopen","verify","--reason","try to launder")
      run(dir,{}, "change","reopen","c1","--reason","x")
      $log << "## PAC-05 hand-edited malformed release blocks\n"
      path = "#{dir}/changes/c1/metadata.yml"
      orig = File.read(path)
      variants = {
        "no release block" => ->(m){ m.delete("release") },
        "empty items" => ->(m){ m["release"]["items"] = [] },
        "items null" => ->(m){ m["release"]["items"] = nil },
        "release scalar" => ->(m){ m["release"] = "yes" },
        "dup ids" => ->(m){ m["release"]["items"] = [{"id"=>"A","description"=>"a"},{"id"=>"A","description"=>"b"}] },
        "judgment items dropped" => ->(m){ m["release"]["items"] = [{"id"=>"A","description"=>"a"}] },
        "item ids renamed" => ->(m){ m["release"]["items"] = [{"id"=>"UND-1X","description"=>"a"},{"id"=>"UND-2X","description"=>"b"}] },
        "all discharged" => ->(m){ m["release"]["items"].each{|i| i["discharged_at"]="2026-01-01T00:00:00Z"} },
        "discharged_at false-y string" => ->(m){ m["release"]["items"].each{|i| i["discharged_at"]="" } },
        "items hash not array" => ->(m){ m["release"]["items"] = {"id"=>"A","description"=>"b"} },
      }
      base = YAML.safe_load(orig, permitted_classes: [Time, Date, Symbol], aliases: true)
      variants.each do |name, fn|
        m = Marshal.load(Marshal.dump(base)); fn.call(m)
        File.write(path, YAML.dump(m))
        $log << "### variant: #{name}\n"
        run(dir,{}, "check")
        run(dir,{}, "ci")
        run(dir,{}, "change","close","c1")
        run(dir,{}, "change","status","c1")
        run(dir,{}, "change","list")
        File.write(path, orig)
      end
    end
    File.write("/tmp/sfa-ev/drive3.txt", $log)
  end
end
D.new.go
