$LOAD_PATH.unshift File.join(ARGV[0], "lib")
require "soft_foundry/harness_eval"; require "tmpdir"
plane = SoftFoundry::ControlPlane.new(ARGV[0])
def y(files) = "id: c1\nkind: gate\ndescription: x\nexpect: {phase: intake, outcome: pass}\nrepository: {files: #{files}}\n"
big = ->(n){ "x" * n }
cases = {
  "65536 bytes" => y("{a.txt: '#{big.(65_536)}'}"),
  "65537 bytes" => y("{a.txt: '#{big.(65_537)}'}"),
  "65537 bytes in a block scalar" => "id: c1\nkind: gate\ndescription: x\nexpect: {phase: intake, outcome: pass}\nrepository:\n  files:\n    a.txt: |\n      #{big.(65_537)}\n",
  "YAML alias amplification" => "id: c1\nkind: gate\ndescription: x\nexpect: {phase: intake, outcome: pass}\nrepository:\n  files:\n    a.txt: &a #{big.(60_000)}\n    b.txt: *a\n",
  "200 files of 64 KiB (12.5 MB total)" => y("{" + (1..200).map { |i| "f#{i}.txt: '#{big.(65_536)}'" }.join(", ") + "}"),
  "a/b and a/./b (same file twice)" => y("{a/b: one, a/./b: two}"),
  "non-string content (list)" => y("{a.txt: [#{(1..20000).map { 'x' * 8 }.join(',')}]}"),
}
Dir.mktmpdir do |d|
  cases.each do |label, body|
    path = File.join(d, "c1.yml"); File.write(path, body)
    r = begin; SoftFoundry::HarnessEval.load_case(path, plane); "loaded"; rescue Exception => e; "#{e.class.name.split('::').last}: #{e.message[0, 90]}"; end
    puts "#{label}: #{r}"
  end
end
