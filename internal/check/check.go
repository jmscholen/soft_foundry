package check

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jmscholen/soft_foundry/internal/plane"
	"github.com/jmscholen/soft_foundry/internal/scan"
)

type Finding struct {
	Level   string
	Message string
}

type Check struct {
	Plane *plane.Plane
}

func New(p *plane.Plane) *Check { return &Check{Plane: p} }

func (c *Check) Run() []Finding {
	var out []Finding
	if !c.Plane.Present() {
		return []Finding{{"error", ".ai/workflow.yml is missing"}}
	}
	if len(c.Plane.Phases()) == 0 {
		out = append(out, Finding{"error", ".ai/workflow.yml declares no lifecycle phases"})
	}
	for _, ph := range c.Plane.Phases() {
		if _, err := c.Plane.Skill(ph.Skill); err != nil {
			out = append(out, Finding{"error", "phase " + ph.ID + " names unknown skill " + ph.Skill})
		}
	}
	for _, name := range c.Plane.SkillNames() {
		sk, err := c.Plane.Skill(name)
		if err != nil {
			out = append(out, Finding{"error", err.Error()})
			continue
		}
		for _, f := range []string{"skill.yml", "SKILL.md", "permissions.yml", "requirements.yml", "completion.yml"} {
			if _, err := os.Stat(filepath.Join(sk.Dir, f)); err != nil {
				out = append(out, Finding{"error", "skill " + name + " missing " + f})
			}
		}
	}
	if _, err := os.Stat(filepath.Join(c.Plane.Root, "AGENTS.md")); err != nil {
		out = append(out, Finding{"warning", "AGENTS.md is missing"})
	}
	for _, f := range scan.ScanPaths(c.Plane.Root, scan.ControlPlanePaths(c.Plane.Root)) {
		out = append(out, Finding{f.Level, fmt.Sprintf("%s:%d %s: %s", f.Path, f.Line, f.Kind, f.Detail)})
	}
	return out
}

func Format(f Finding) string {
	if f.Level == "error" {
		return "✗ error " + f.Message
	}
	return "! warning " + f.Message
}

func Errors(fs []Finding) int {
	n := 0
	for _, f := range fs {
		if f.Level == "error" {
			n++
		}
	}
	return n
}

func Summarize(fs []Finding) string {
	return strings.TrimSpace(fmt.Sprintf("%d findings", len(fs)))
}
