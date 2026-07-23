package main

import (
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strings"
)

type facts struct {
	distroID   string
	distroName string

	homeDir   string
	hostname  string
	userShell string

	hasHyprCfg    bool
	hasQsCfg      bool
	hasRainBin    bool
	hasGo         bool
	hasHyprland   bool
	hasQuickshell bool
	hasGit        bool

	symlinksOk    bool
	rainInstalled bool

	prevRun *runState
}

func has(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func detect() *facts {
	f := &facts{}

	if b, err := os.ReadFile("/etc/os-release"); err == nil {
		for _, ln := range strings.Split(string(b), "\n") {
			k, v, ok := strings.Cut(ln, "=")
			if !ok {
				continue
			}
			v = strings.Trim(v, `"`)
			switch k {
			case "ID":
				f.distroID = v
			case "PRETTY_NAME":
				f.distroName = v
			}
		}
	}

	u, err := user.Current()
	if err == nil {
		f.homeDir = u.HomeDir
	}
	if f.homeDir == "" {
		f.homeDir, _ = os.UserHomeDir()
	}
	f.hostname, _ = os.Hostname()
	f.userShell = os.Getenv("SHELL")

	cfg := filepath.Join(f.homeDir, ".config")
	if _, err := os.Stat(filepath.Join(cfg, "hypr")); err == nil {
		f.hasHyprCfg = true
	}
	if _, err := os.Stat(filepath.Join(cfg, "quickshell")); err == nil {
		f.hasQsCfg = true
	}

	bin := filepath.Join(cfg, "rain", "rain")
	if _, err := os.Stat(bin); err == nil {
		f.hasRainBin = true
	}

	f.hasGo = has("go")
	f.hasHyprland = has("Hyprland")
	f.hasQuickshell = has("quickshell")
	f.hasGit = has("git")

	// Check if symlinks point to the repo
	repo := findRepo()
	if repo != "" {
		for _, dir := range []string{"hypr", "quickshell"} {
			target := filepath.Join(cfg, dir)
			if link, err := os.Readlink(target); err == nil {
				if filepath.IsAbs(link) {
					if strings.HasPrefix(link, repo) {
						f.symlinksOk = true
					}
				}
			}
		}
	}

	f.rainInstalled = f.symlinksOk && f.hasRainBin
	f.prevRun = loadState(f.homeDir)

	return f
}

func findRepo() string {
	// Walk up from the installer binary or cwd
	candidates := []string{
		filepath.Dir(os.Args[0]),
		".",
	}
	if d, err := os.Getwd(); err == nil {
		candidates = append(candidates, d)
	}
	for _, c := range candidates {
		if strings.HasPrefix(c, "/tmp") {
			continue
		}
		p := filepath.Join(c, "rain", "config", "hypr")
		if _, err := os.Stat(p); err == nil {
			return filepath.Dir(filepath.Dir(filepath.Dir(p)))
		}
		// Also check parent
		p = filepath.Join(c, "..", "rain", "config", "hypr")
		if _, err := os.Stat(p); err == nil {
			abs, _ := filepath.Abs(c)
			return filepath.Dir(filepath.Dir(filepath.Dir(filepath.Join(abs, "..", "rain", "config", "hypr"))))
		}
	}
	// Last resort: check $RAIN_DOTS or $HOME/raindots
	for _, d := range []string{os.Getenv("RAIN_DOTS"), filepath.Join(os.Getenv("HOME"), "raindots")} {
		if d == "" {
			continue
		}
		if _, err := os.Stat(filepath.Join(d, "rain", "config", "hypr")); err == nil {
			return d
		}
	}
	return ""
}

func (f *facts) repoRoot() string {
	return findRepo()
}

func (f *facts) needsDeps() bool {
	return !f.hasHyprland || !f.hasQuickshell || !f.hasGit
}

var depsNotice = "go, git, hyprland, quickshell, and other packages required for the Rain desktop"

func (f *facts) gpuSummary() string {
	cards, _ := filepath.Glob("/sys/class/drm/card*/device/uevent")
	seen := map[string]bool{}
	for _, c := range cards {
		b, err := os.ReadFile(c)
		if err != nil {
			continue
		}
		for _, ln := range strings.Split(string(b), "\n") {
			if drv, ok := strings.CutPrefix(ln, "DRIVER="); ok && !seen[drv] {
				seen[drv] = true
			}
		}
	}
	if len(seen) == 0 {
		return "none detected"
	}
	var out []string
	for d := range seen {
		out = append(out, d)
	}
	return strings.Join(out, ", ")
}
