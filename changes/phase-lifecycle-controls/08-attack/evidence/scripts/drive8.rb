require "/tmp/sfa/test/lifecycle_fixture"
require "open3"; require "json"
class D
  include LifecycleFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def g(dir, env, tool, input, label)
    o,e,s = Open3.capture3(E.merge(env),"/tmp/sfbin/sf","guard",stdin_data: JSON.dump({"tool_name"=>tool,"tool_input"=>input,"cwd"=>dir}),chdir: dir)
    $log << "#{label} :: exit=#{s.exitstatus} #{(o+e).lines.first.to_s.strip[0,170]}\n"
  end
  def go
    $log = +"## PAC-02 guard under session markers (attack-phase record, write to 08-attack vs 07-evaluation vs app)\n"
    with_lifecycle_record("c1", complete: %w[intake discover specify threat_model plan implement verify], current_phase: "attack") do |dir, record|
      w = ->(p){ {"file_path"=>File.join(dir,p),"content"=>"x"} }
      { "attack"=>"attack", "evaluate"=>"evaluate", "unknown"=>"nosuch", "empty"=>"", "mixed-case"=>"Attack", "traversal"=>"../x", "trailing newline"=>"attack\n", "implement (non-isolated)"=>"implement", "space"=>"attack " }.each do |k,v|
        env = {"SOFT_FOUNDRY_PHASE"=>v}
        g(dir, env, "Write", w.("changes/c1/08-attack/results.md"), "marker=#{k}: write own dir")
        g(dir, env, "Write", w.("changes/c1/07-evaluation/results.md"), "marker=#{k}: write sibling dir")
        g(dir, env, "Write", w.("lib/app.rb"), "marker=#{k}: write app code")
      end
      env = {"SOFT_FOUNDRY_PHASE"=>"attack","SOFT_FOUNDRY_PARALLEL"=>"1"}
      g(dir, env, "Write", w.("changes/c1/07-evaluation/results.md"), "parallel attack: write sibling dir")
      g(dir, env, "Write", w.("changes/c1/08-attack/results.md"), "parallel attack: write own dir")
      g(dir, {"SOFT_FOUNDRY_PHASE"=>"implement","SOFT_FOUNDRY_PARALLEL"=>"1"}, "Write", w.("lib/app.rb"), "parallel marker=implement: write app")
      g(dir, {"SOFT_FOUNDRY_PHASE"=>"attack"}, "Bash", {"command"=>"soft-foundry phase reopen verify --reason x"}, "attack session Bash: soft-foundry phase reopen")
      g(dir, {"SOFT_FOUNDRY_PHASE"=>"attack"}, "Bash", {"command"=>"env -u SOFT_FOUNDRY_PHASE soft-foundry change release c1 --item A=a"}, "attack session Bash: env -u marker then release")
      g(dir, {"SOFT_FOUNDRY_PHASE"=>"attack"}, "Bash", {"command"=>"SOFT_FOUNDRY_PHASE=judge soft-foundry change discharge A --note x"}, "attack session Bash: rewrite marker then discharge")
      g(dir, {"SOFT_FOUNDRY_PHASE"=>"attack"}, "Edit", {"file_path"=>File.join(dir,"changes/c1/metadata.yml"),"old_string"=>"a","new_string"=>"b"}, "attack session Edit metadata.yml (status/release hand edit)")
      g(dir, {"SOFT_FOUNDRY_PHASE"=>"attack"}, "Edit", {"file_path"=>File.join(dir,"changes/c1/07-evaluation/handoff.yml"),"old_string"=>"a","new_string"=>"b"}, "attack session Edit sibling handoff")
    end
    File.write("/tmp/sfa-ev/drive8.txt", $log)
  end
end
D.new.go
