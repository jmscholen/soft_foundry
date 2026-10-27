require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
require "json"
require "yaml"
# ATTACK-017: blank and odd discharged_at values through check, ci, change close, status, and the UI JSON
class D
  include FinishedFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def run(dir, *args)
    o,e,s = Open3.capture3(E,"/tmp/sfbin/sf",*args,chdir: dir)
    keep = (o+e).lines.reject{|l| l=~/^\s*✓ pass eval|advisory/}.join.scrub[0,400]
    $log << "$ sf #{args.map(&:inspect).join(' ')}\nexit=#{s.exitstatus}\n#{keep}\n"
    s.exitstatus
  end
  def go
    $log = +""
    ENV["HOME"] = Dir.mktmpdir("sfhome")
    vals = { "empty" => "", "space" => " ", "tab-newline" => "\t\n", "nbsp" => " ", "false" => false, "zero" => 0, "empty array" => [], "empty hash" => {}, "null" => nil, "junk string" => "not a time", "bare date" => Date.new(2026,1,1) }
    vals.each do |name, v|
      with_finished_record("c1", undischarged: ["UND-1"]) do |dir, record|
        $log << "### discharged_at = #{name} (#{v.inspect})\n"
        run(dir, "change","release","c1","--item","A=a")
        path = "#{dir}/changes/c1/metadata.yml"
        m = YAML.safe_load_file(path, permitted_classes: [Time, Date])
        m["release"]["items"].each { |i| i["discharged_at"] = v }
        File.write(path, YAML.dump(m))
        run(dir, "check"); run(dir, "ci"); run(dir, "change","status","c1"); run(dir, "change","close","c1")
        run(dir, "change","discharge","A","--note","real")
        srv = SoftFoundry::UI::Server.new(dir, port: 0)
        h = {"host"=>"127.0.0.1:#{srv.port}", "x-soft-foundry-token"=>srv.token, "sec-fetch-site"=>"same-origin"}
        st, _ct, body, = srv.respond("GET", "/api/change?slug=c1", h)
        js = JSON.parse(body) rescue nil
        $log << "UI /api/change -> #{st}, parses=#{!js.nil?}, timeline 'discharged' entries=#{body.to_s.scan(/"kind":"discharged"/).size}\n\n"
      end
    end
    File.write("/tmp/sfa-ev/drive13.txt", $log)
  end
end
D.new.go
