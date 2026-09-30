package gitx

import (
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

type Git struct {
	Root string
}

func New(root string) *Git {
	abs, err := filepath.Abs(root)
	if err != nil {
		abs = root
	}
	return &Git{Root: abs}
}

func (g *Git) run(args ...string) (string, bool) {
	cmd := exec.Command("git", append([]string{"-C", g.Root}, args...)...)
	var env []string
	for _, e := range os.Environ() {
		if strings.HasPrefix(e, "GIT_DIR=") || strings.HasPrefix(e, "GIT_WORK_TREE=") {
			continue
		}
		env = append(env, e)
	}
	cmd.Env = env
	out, err := cmd.CombinedOutput()
	return string(out), err == nil
}

func (g *Git) Repository() bool {
	out, ok := g.run("rev-parse", "--is-inside-work-tree")
	return ok && strings.TrimSpace(out) == "true"
}

func (g *Git) HeadSHA() string {
	out, ok := g.run("rev-parse", "HEAD")
	if !ok {
		return ""
	}
	return strings.TrimSpace(out)
}

func (g *Git) Branch() string {
	out, ok := g.run("rev-parse", "--abbrev-ref", "HEAD")
	if !ok {
		return ""
	}
	return strings.TrimSpace(out)
}

func (g *Git) UserName() string {
	out, ok := g.run("config", "user.name")
	if !ok {
		return ""
	}
	return strings.TrimSpace(out)
}

func (g *Git) Toplevel() string {
	out, ok := g.run("rev-parse", "--show-toplevel")
	if !ok {
		return ""
	}
	return strings.TrimSpace(out)
}

func (g *Git) Commit(sha string) bool {
	_, ok := g.run("cat-file", "-e", sha+"^{commit}")
	return ok
}

func (g *Git) FileAt(sha, path string) bool {
	_, ok := g.run("cat-file", "-e", sha+":"+path)
	return ok
}

func (g *Git) DefaultBranch() string {
	out, ok := g.run("symbolic-ref", "-q", "--short", "refs/remotes/origin/HEAD")
	if ok {
		s := strings.TrimSpace(out)
		s = strings.TrimPrefix(s, "origin/")
		if s != "" {
			return s
		}
	}
	for _, b := range []string{"main", "master"} {
		if _, ok := g.run("show-ref", "--verify", "--quiet", "refs/heads/"+b); ok {
			return b
		}
	}
	return ""
}

var shaRE = regexp.MustCompile(`\A[0-9a-f]{7,40}\z`)

func (g *Git) Ancestor(sha, ref string) bool {
	if !shaRE.MatchString(sha) || ref == "" {
		return false
	}
	_, ok := g.run("merge-base", "--is-ancestor", sha, ref)
	return ok
}

func (g *Git) ChangedSince(sha string) []string {
	out, ok := g.run("diff", "--name-only", sha, "HEAD")
	var committed []string
	if ok {
		committed = splitLines(out)
	}
	return uniqueSorted(append(committed, g.DirtyPaths()...))
}

func (g *Git) ChangedBetween(sha, tip string) []string {
	out, ok := g.run("diff", "--name-only", sha, tip)
	if !ok {
		return nil
	}
	return uniqueSorted(splitLines(out))
}

func (g *Git) BranchTip(name string) string {
	name = strings.TrimSpace(name)
	if name == "" || name == "HEAD" {
		return ""
	}
	for _, ref := range []string{"refs/heads/" + name, "refs/remotes/origin/" + name} {
		if _, ok := g.run("show-ref", "--verify", "--quiet", ref); !ok {
			continue
		}
		out, ok := g.run("rev-parse", ref)
		if ok {
			return strings.TrimSpace(out)
		}
	}
	return ""
}

func (g *Git) DirtyPaths() []string {
	out, ok := g.run("status", "--porcelain", "--untracked-files=all", "--ignored=matching")
	if !ok {
		return nil
	}
	var paths []string
	for _, line := range splitLines(out) {
		if len(line) < 4 {
			continue
		}
		p := line[3:]
		if i := strings.Index(p, " -> "); i >= 0 {
			p = p[i+4:]
		}
		paths = append(paths, p)
	}
	return paths
}

func splitLines(s string) []string {
	var out []string
	for _, line := range strings.Split(s, "\n") {
		line = strings.TrimRight(line, "\r")
		if line != "" {
			out = append(out, line)
		}
	}
	return out
}

func uniqueSorted(in []string) []string {
	seen := map[string]struct{}{}
	var out []string
	for _, s := range in {
		if _, ok := seen[s]; ok {
			continue
		}
		seen[s] = struct{}{}
		out = append(out, s)
	}
	return out
}
