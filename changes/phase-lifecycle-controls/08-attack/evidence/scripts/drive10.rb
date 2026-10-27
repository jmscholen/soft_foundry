require "/tmp/sfa/test/lifecycle_fixture"
require "open3"; require "yaml"
class D
  include FinishedFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def run(dir, env, *args)
    o,e,s = Open3.capture3(E.merge(env),"/tmp/sfbin/sf",*args,chdir: dir)
    $log << "$ #{env.empty? ? '' : env.inspect+' '}sf #{args.map(&:inspect).join(' ')}\nexit=#{s.exitstatus}\n#{(o+e).lines.reject{|l| l=~/✓|^\s+[01]\d-|advisory|! warn/}.join[0,700]}\n"
  end
  def go
    $log = +"## hostile released record through CLI consumers\n"
    with_finished_record("c1", undischarged: ["UND-1"]) do |dir, record|
      path = "#{dir}/changes/c1/metadata.yml"
      m = YAML.safe_load_file(path, permitted_classes: [Time, Date])
      m["status"]="released"
      m["release"]={"at"=>"x","commit"=>nil,"items"=>[{"id"=>7,"description"=>{"n"=>1}},"junk",nil,{"id"=>"UND-1","description"=>"d"}]}
      m["phase_reopenings"]=["junk",nil,{"reason"=>{"a"=>1},"reset"=>"notalist","at"=>5}]
      File.write(path, YAML.dump(m))
      %w[status list].each { |c| run(dir,{}, "change",c,*(c=="status" ? ["c1"] : [])) }
      run(dir,{}, "check"); run(dir,{}, "ci")
      run(dir,{}, "change","discharge","7","--note","n")
      run(dir,{}, "change","close","c1","--force")
      run(dir,{}, "timeline","c1") ; run(dir,{}, "ps"); run(dir,{}, "scope","c1")
    end
    $log << "## env -u marker bypass (documented residual)\n"
    with_finished_record("c2") do |dir, record|
      o,e,s = Open3.capture3(E.merge({"SOFT_FOUNDRY_PHASE"=>"attack"}), "sh","-c","env -u SOFT_FOUNDRY_PHASE /tmp/sfbin/sf change release c2 --item A=a", chdir: dir)
      $log << "session(marker=attack) runs `env -u SOFT_FOUNDRY_PHASE soft-foundry change release` -> exit #{s.exitstatus}: #{(o+e).lines.first.to_s.strip}\n"
    end
    File.write("/tmp/sfa-ev/drive10.txt", $log)
  end
end
D.new.go
