package scan

import "testing"

func TestScanTextSecret(t *testing.T) {
	f := ScanText("notes.md", "key=AKIAIOSFODNN7EXAMPLE\n")
	if len(f) == 0 {
		t.Fatal("expected secret finding")
	}
	if f[0].Kind != "secret" {
		t.Fatalf("got %s", f[0].Kind)
	}
}

func TestScanAllow(t *testing.T) {
	f := ScanText("notes.md", "key=AKIAIOSFODNN7EXAMPLE soft-foundry:scan-allow\n")
	for _, x := range f {
		if x.Kind == "secret" {
			t.Fatal("allow marker should exempt secrets")
		}
	}
}

func TestInvisibleAlwaysErrors(t *testing.T) {
	f := ScanText("notes.md", "hello\u200bworld soft-foundry:scan-allow\n")
	found := false
	for _, x := range f {
		if x.Kind == "invisible" && x.Level == "error" {
			found = true
		}
	}
	if !found {
		t.Fatal("invisible text must remain an error")
	}
}
