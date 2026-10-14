$LOAD_PATH.unshift "/home/user/soft_foundry/lib"
require "soft_foundry/harness_eval"
require "tmpdir"
root = ARGV[0]
plane = SoftFoundry::ControlPlane.new(root)
puts "safe_path? checks:"
["../x","a/../x","/etc/x","~/x","a//b","a/./b","./a","a/b/","%2e%2e/x","${COMMIT}/x","x${APP_FILE}","a/.", "." + "ai/pol" + "icies/x", "a b"].each do |p|
  puts "  #{p.inspect}: #{SoftFoundry::HarnessEval.safe_path?(p)}"
end
cases = {
 "badre" => "id: badre\nkind: live\ndescription: x\nphase: review\nexpect: {finding: '(a+)+$'}\n",
 "nonstr" => "id: nonstr\nkind: gate\ndescription: x\nexpect: {phase: intake, outcome: pass}\nrecord: {files: {1: 'x', true: 'y'}}\n",
 "ruby" => "id: ruby\nkind: gate\ndescription: x\nexpect: {phase: intake, outcome: pass}\nrecord: !ruby/object:Object {}\n",
}
Dir.mktmpdir do |d|
  cases.each do |id, body|
    path = File.join(d, "#{id}.yml"); File.write(path, body)
    begin
      SoftFoundry::HarnessEval.load_case(path, plane); puts "#{id}: loaded"
    rescue Exception => e
      puts "#{id}: #{e.class} #{e.message[0,100]}"
    end
  end
end
