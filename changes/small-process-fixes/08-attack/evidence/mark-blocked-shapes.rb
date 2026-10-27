$LOAD_PATH.unshift("/tmp/sfa/repo/lib"); require "soft_foundry"; require "timeout"
root="/tmp/sfa/repo"; plane=SoftFoundry::ControlPlane.new(root) rescue (plane=SoftFoundry::ControlPlane.load(root))
rec=SoftFoundry::ChangeRecord.new(root,"ok8",control_plane: plane)
phase=plane.phases.find{|p|p.id=="attack"}
runner=SoftFoundry::PhaseRunner.new(root, record: rec, plane: plane, git: SoftFoundry::Git.new(root))
path=rec.handoff_path(phase)
def t(label, body, path, runner, phase)
  File.write(path, body)
  r = begin
    Timeout.timeout(15){ runner.mark_blocked!(phase) }
  rescue Exception => e
    "#{e.class}: #{e.message.to_s[0,80]}"
  end
  puts "#{label}: -> #{r.inspect}"; puts File.read(path)[0,400].lines.grep(/status|notes|blocking|^#/).join if r.is_a?(Integer)
end
t("complete+blocking", "# keep me\nstatus: complete\nblocking:\n  - a\n  - b\nnotes: hi\nother: &x [1]\nref: *x\n", path, runner, phase)
t("Complete cased", "status: Complete\nblocking: [a]\n", path, runner, phase)
t("blocking string", "status: complete\nblocking: stop\n", path, runner, phase)
t("blocking blank", "status: complete\nblocking: ['']\n", path, runner, phase)
t("status in_progress+blocking", "status: in_progress\nblocking: [a]\n", path, runner, phase)
t("notes non-string", "status: complete\nblocking: [a]\nnotes: [1,2]\n", path, runner, phase)
bomb = "a: &a0 [x,x,x,x,x,x,x,x,x]\n" + (1..9).map{|i| "a#{i}: &a#{i} [#{(["*a#{i-1}"]*9).join(',')}]\n"}.join + "status: complete\nblocking: [z]\n"
t("alias bomb", bomb, path, runner, phase)
puts "bomb-sum-size: n/a"
