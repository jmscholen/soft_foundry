$LOAD_PATH.unshift("/tmp/sfa/repo/lib"); require "soft_foundry"
root="/tmp/sfa/repo"; plane=SoftFoundry::ControlPlane.new(root)
rec=SoftFoundry::ChangeRecord.new(root,"ok8",control_plane: plane)
g=SoftFoundry::Gate.new(rec, git: SoftFoundry::Git.new(root))
[[""],["  "],["["],["{a,b"],["**"],["/abs/**"],["../x"],[nil],[1],"lib/**",{"a"=>1},["a<0xE2><0x80><0x8B>b"],["a\nb"]].each{|raw|
 r=(g.send(:access_control_problems, raw) rescue "RAISED #{$!.class}")
 puts "#{raw.inspect[0,30]} => #{r.inspect[0,110]}"}
