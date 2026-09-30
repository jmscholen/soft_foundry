package cli

import (
	"bytes"
	"os"
	"path/filepath"
	"testing"
)

func TestVersion(t *testing.T) {
	var out bytes.Buffer
	code := New([]string{"version"}, t.TempDir(), &out, &out, nil).Run()
	if code != 0 {
		t.Fatalf("exit %d", code)
	}
	if out.Len() == 0 {
		t.Fatal("expected version output")
	}
}

func TestHelpUnknown(t *testing.T) {
	var out bytes.Buffer
	code := New([]string{"nope"}, t.TempDir(), &out, &out, nil).Run()
	if code != 1 {
		t.Fatalf("exit %d", code)
	}
}

func TestOnboardWritesRuntime(t *testing.T) {
	dir := t.TempDir()
	var out bytes.Buffer
	code := New([]string{"onboard"}, dir, &out, &out, nil).Run()
	if code != 0 {
		t.Fatalf("exit %d: %s", code, out.String())
	}
	if _, err := os.Stat(filepath.Join(dir, ".soft-foundry", "runtime.yml")); err != nil {
		t.Fatal(err)
	}
}
