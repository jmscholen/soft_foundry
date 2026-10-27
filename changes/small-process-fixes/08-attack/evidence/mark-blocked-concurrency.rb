$LOAD_PATH.unshift("/tmp/sfa/repo/lib"); require "soft_foundry"
root="/tmp/sfa/repo"; plane=SoftFoundry::ControlPlane.new(root)
rec=SoftFoundry::ChangeRecord.new(root,"ok8",control_plane: plane)
runner=SoftFoundry::PhaseRunner.new(root, record: rec, plane: plane, git: SoftFoundry::Git.new(root))
ph=plane.phases.first(8)
ph.each{|p| File.write(rec.handoff_path(p), "phase: #{p.id}\nstatus: complete\nblocking: [x#{p.id}]\nnotes: ''\nexecuted_by: {a: 1}\n")}
pids=3.times.map{|k| fork{ ph.each{|p| runner.mark_blocked!(p); runner.finish!(p, 0) rescue puts("finish err #{$!.class}") } }}
pids.each{|pid| Process.wait(pid)}
ph.each{|p| h=rec.handoff(p); puts [p.id,h["status"],h["blocking"].inspect,h["notes"].scan("Marked").size, h.dig("executed_by","exit_status").inspect].join(" ")}
