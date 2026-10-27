require "/tmp/sfa/test/lifecycle_fixture"
require "open3"
class D
  include FinishedFixture
  E = {"SOFT_FOUNDRY_PHASE"=>nil,"SOFT_FOUNDRY_PARALLEL"=>nil}
  def run(dir,*args)
    o,e,s = Open3.capture3(E,"/tmp/sfbin/sf",*args,chdir: dir); [s.exitstatus,(o+e).lines.reject{|l| l=~/advisory|! warn|^\s+✓/}.join.scrub[0,200]]
  end
  def go
    $log = +"## ATTACK-007 rerun: invisible and look-alike characters through --reason, --item, --note (after remediation)\n"
    cases = {"ZWSP 200B"=>"a\u{200B}b","ZWNJ 200C"=>"a\u{200C}b","BOM FEFF"=>"a\u{FEFF}b","bidi 202E"=>"a\u{202E}b","bidi isolate 2066"=>"a\u{2066}b","line sep 2028"=>"a\u{2028}b","para sep 2029"=>"a\u{2029}b","word joiner 2060"=>"a\u{2060}b","tag E0041"=>"a\u{E0041}b","soft hyphen AD"=>"a\u{00AD}b","mongolian 180E"=>"a\u{180E}b",
      "nbsp A0"=>"a b","hangul filler 3164"=>"a\u{3164}b","braille blank 2800"=>"a\u{2800}b","variation sel FE0F"=>"a️b","combining 0338"=>"a̸b","cyrillic a 0430"=>"pаss","private use E000"=>"ab","object repl FFFC"=>"a￼b","invalid utf8"=>"a\xFFb".dup.force_encoding("BINARY"),"ctrl C1 9B"=>"a\u009Bb","plain"=>"fixed the race"}
    cases.each do |name, v|
      with_finished_record("c1", undischarged: ["UND-1"]) do |dir, record|
        c,m = run(dir,"phase","reopen","verify","--reason",v) rescue [:spawn_err, $!.class.to_s]
        sc = c==0 ? run(dir,"scan") : [nil,""]
        $log << "reason #{name}: exit=#{c} scan_after=#{sc[0].inspect} #{m.lines.first.to_s.strip[0,110]}\n"
      end
    end
    ["a\u{200B}b","a\u{202E}b"].each do |v|
      with_finished_record("c1", undischarged: ["UND-1"]) do |dir, record|
        $log << "item zwsp/bidi: #{run(dir,'change','release','c1','--item',"A=#{v}").first}; "
        $log << "discharge note: #{run(dir,'change','discharge','UND-1','--note',v).first}\n"
      end
    end
    File.write("/tmp/sfa-ev/drive12.txt", $log)
  end
end
D.new.go
