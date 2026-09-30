package shellx

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var Commands = map[string]string{
	"claude": "claude",
	"codex":  "codex",
	"grok":   "grok",
}

func Resolve(name string) (string, error) {
	cmd, ok := Commands[name]
	if !ok {
		return "", fmt.Errorf("unknown shell %q. Supported: claude, codex, grok", name)
	}
	for _, dir := range strings.Split(os.Getenv("PATH"), string(os.PathListSeparator)) {
		p := filepath.Join(dir, cmd)
		if st, err := os.Stat(p); err == nil && !st.IsDir() && st.Mode()&0o111 != 0 {
			return p, nil
		}
	}
	if p, err := exec.LookPath(cmd); err == nil {
		return p, nil
	}
	return "", fmt.Errorf("%s is not installed or not on PATH", cmd)
}

func Launch(name string, args []string) error {
	bin, err := Resolve(name)
	if err != nil {
		return err
	}
	c := exec.Command(bin, args...)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return c.Run()
}
