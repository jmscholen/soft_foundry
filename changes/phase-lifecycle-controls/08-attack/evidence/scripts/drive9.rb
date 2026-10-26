require "/tmp/sfa/test/lifecycle_fixture"
require "json"; require "yaml"
class D
  include FinishedFixture
  def go
    $log = +"## PAC-12 UI/snapshot with hostile record text (in-process Server#respond, no socket)\n"
    ENV["HOME"] = Dir.mktmpdir("sfhome")
    with_finished_record("c1", undischarged: ["UND-1"]) do |dir, record|
      path = "#{dir}/changes/c1/metadata.yml"
      m = YAML.safe_load_file(path, permitted_classes: [Time, Date])
      xss = "<script>alert(1)</script><img src=x onerror=alert(2)>"
      m["status"] = "released"
      m["release"] = {"at"=>"2026-10-26T00:00:00Z","commit"=>"abc","items"=>[
        {"id"=>"<b>X</b>","description"=>xss,"discharged_at"=>"2026-10-26T00:00:00Z","discharge_note"=>xss},
        {"id"=>7,"description"=>{"nested"=>[1,2]}},
        {"id"=>"BIG","description"=>"A"*200_000},
        "not a mapping", nil, ["x"]]}
      m["phase_reopenings"] = [{"at"=>"2026-10-26T00:00:00Z","phase"=>"verify","reset"=>["verify"],"from_commit"=>"abcdef1","reason"=>xss,"source"=>"manual"}, "junk", nil, {"reason"=>{"a"=>1}}]
      File.write(path, YAML.dump(m)); commit_all(dir, "hostile")
      srv = SoftFoundry::UI::Server.new(dir, port: 0)
      srv.instance_variable_set(:@port, 4321) rescue nil
      h = {"host"=>"127.0.0.1:#{srv.port}", "x-soft-foundry-token"=>srv.token, "sec-fetch-site"=>"same-origin"}
      %w[/api/changes /api/change?slug=c1].each do |t|
        begin
          st, ct, body, = srv.respond("GET", t, h)
          $log << "GET #{t} -> #{st} #{ct}, #{body.to_s.bytesize} bytes, JSON parses: #{(JSON.parse(body); true) rescue false}, raw '<script' in body: #{body.to_s.include?('<script')}\n"
        rescue => e
          $log << "GET #{t} -> EXCEPTION #{e.class}: #{e.message[0,150]}\n"
        end
      end
      %w[POST PUT DELETE PATCH OPTIONS].each { |v| st, = srv.respond(v, "/api/changes", h); $log << "#{v} /api/changes -> #{st}\n" }
      $log << "GET without token -> #{srv.respond('GET','/api/changes', h.reject{|k,_| k=~/token/}).first}\n"
      $log << "GET wrong host -> #{srv.respond('GET','/api/changes', h.merge('host'=>'evil.example:80')).first}\n"
      $log << "GET cross-site -> #{srv.respond('GET','/api/changes', h.merge('sec-fetch-site'=>'cross-site')).first}\n"
      $log << "GET slug traversal -> #{srv.respond('GET','/api/change?slug=../../etc/passwd', h).first}\n"
      $log << "GET /api/export (new route probe) -> #{srv.respond('GET','/api/release', h).first}\n"
      # snapshot HTML/report output
      begin
        snap = SoftFoundry::Snapshot.new(dir, plane: SoftFoundry::ControlPlane.new(dir), git: SoftFoundry::Git.new(dir), index: SoftFoundry::ChangeIndex.new(dir, plane: SoftFoundry::ControlPlane.new(dir), git: SoftFoundry::Git.new(dir))) rescue nil
        $log << "Snapshot.new ok: #{!snap.nil?}\n"
      end
      # timeline text via CLI
    end
    File.write("/tmp/sfa-ev/drive9.txt", $log)
  end
end
D.new.go
