$LOAD_PATH.unshift("/tmp/sfa/repo/lib"); require "soft_foundry"
root="/tmp/sfa/repo"; plane=SoftFoundry::ControlPlane.new(root)
rec=SoftFoundry::ChangeRecord.new(root,"ok8",control_plane: plane)
g=SoftFoundry::Gate.new(rec, git: SoftFoundry::Git.new(root))
def c(h) = {"id"=>"C"}.merge(h)
cases={
 "none"=>{"checks"=>[c({})]},
 "all NA no note"=>{"checks"=>[c("protection"=>"not_applicable")]},
 "all NA boilerplate"=>{"checks"=>[c("protection"=>"not_applicable","protection_note"=>"n/a")]},
 "disabled blank note"=>{"checks"=>[c("protection"=>"disabled","protection_note"=>"  ")]},
 "disabled note"=>{"checks"=>[c("protection"=>"disabled","protection_note"=>"x")]},
 "in_force alongside disabled-no-note"=>{"checks"=>[c("protection"=>"in_force"),c("id"=>"D","protection"=>"disabled")]},
 "in_force case"=>{"checks"=>[c("protection"=>"In_Force")]},
 "in_force sym true"=>{"checks"=>[c("protection"=>true)]},
 "in_force array"=>{"checks"=>[c("protection"=>["in_force"])]},
 "in_force status failed check"=>{"checks"=>[c("protection"=>"in_force","status"=>"failed")]},
 "checks string"=>{"checks"=>"in_force"},
 "checks empty"=>{"checks"=>[]},
 "nil tests"=>nil,
 "tests array"=>[1],
 "checks with non-hash"=>{"checks"=>["in_force",1]},
 "note non-string"=>{"checks"=>[c("protection"=>"disabled","protection_note"=>["a"])]},
}
cases.each{|k,v| r=(g.send(:protection_findings, v, ["lib/x.rb"]) rescue "RAISED #{$!.class}: #{$!.message[0,60]}"); puts "#{k}: #{r.respond_to?(:status) ? r.status.to_s+' '+r.detail.to_s[0,90] : r}"}
