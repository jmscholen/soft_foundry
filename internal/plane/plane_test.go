package plane

import "testing"

func TestMatchPrefix(t *testing.T) {
	if !Match("lib/soft_foundry/cli.rb", "lib/**") {
		t.Fatal("expected match")
	}
	if Match("vendor/lib/x.rb", "lib/**") {
		t.Fatal("should not match outside prefix")
	}
}
