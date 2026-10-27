require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
require "yaml"
class D
  include FinishedFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def pair(dir, a, b)
    ths = [a,b].map { |args| Thread.new { o,e,s = Open3.capture3(E, "/tmp/sfbin/sf", *args, chdir: dir); [s.exitstatus, (o+e).lines.first(2).join.strip[0,120]] } }
    ths.map(&:value)
  end
  def go
    $log = +""
    inconsistent = 0; dupes = 0; n = 14
    n.times do |i|
      with_finished_record("c1") do |dir, record|
        r = pair(dir, ["change","release","c1","--item","A=a"], ["phase","reopen","verify","--reason","race #{i}"])
        meta = YAML.safe_load_file("#{dir}/changes/c1/metadata.yml", permitted_classes: [Time, Date])
        pending = %w[06-verification 07-evaluation 08-attack 13-review 14-judgment 15-learning].count { |d| YAML.safe_load_file("#{dir}/changes/c1/#{d}/handoff.yml")["status"] == "pending" }
        bad = meta["status"] == "released" && pending > 0
        inconsistent += 1 if bad
        $log << "run #{i}: release/reopen => #{r.map(&:first).inspect} status=#{meta['status']} pending_handoffs=#{pending} reopenings=#{Array(meta['phase_reopenings']).size}#{bad ? ' INCONSISTENT' : ''}\n"
      end
    end
    $log << "inconsistent (released with reset phases): #{inconsistent}/#{n}\n"
    4.times do |i|
      with_finished_record("c1") do |dir, record|
        ths = 4.times.map { |k| Thread.new { o,e,s = Open3.capture3(E, "/tmp/sfbin/sf", "phase","reopen","verify","--reason","dup #{k}", chdir: dir); s.exitstatus } }
        codes = ths.map(&:value)
        meta = YAML.safe_load_file("#{dir}/changes/c1/metadata.yml", permitted_classes: [Time, Date])
        $log << "4 concurrent reopens => exits #{codes.inspect}, phase_reopenings entries=#{Array(meta['phase_reopenings']).size}, YAML parses\n"
      end
    end
    File.write("/tmp/sfa-ev/drive6.txt", $log)
  end
end
D.new.go
