package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type checkStatus int

const (
	statusOK checkStatus = iota
	statusWarn
	statusError
)

type checkResult struct {
	status checkStatus
	name   string
	detail string
	tip    string
}

var (
	colorGreen  = "\x1b[32m"
	colorYellow = "\x1b[33m"
	colorRed    = "\x1b[31m"
	colorReset  = "\x1b[0m"
)

func cmdDoctor(args []string) {
	for _, a := range args {
		if a == "-v" || a == "--verbose" {
			break
		}
	}

	checkTTY()

	fmt.Println("Doctor summary (to see all details, run `rain doctor -v`):")
	fmt.Println()

	checks := runChecks()

	bad := 0
	for _, c := range checks {
		sym, color := "✓", colorGreen
		switch c.status {
		case statusWarn:
			sym, color = "!", colorYellow
		case statusError:
			sym, color = "✗", colorRed
		}

		line := fmt.Sprintf("[%s] %s", sym, c.name)
		if c.detail != "" {
			line += " " + c.detail
		}
		fmt.Printf("%s%s%s\n", color, line, colorReset)

		if c.tip != "" {
			fmt.Printf("    %s%s%s\n", colorYellow, c.tip, colorReset)
		}

		if c.status != statusOK {
			bad++
		}
	}

	fmt.Println()
	if bad == 0 {
		fmt.Printf("%s• No issues found!%s\n", colorGreen, colorReset)
	} else {
		fmt.Printf("%s! Found %d issue(s) in %d check(s).%s\n", colorYellow, bad, len(checks), colorReset)
	}
}

func runChecks() []checkResult {
	var checks []checkResult
	home, _ := os.UserHomeDir()

	hyprctlPath, hyprctlOK := lookPath("hyprctl")
	if !hyprctlOK {
		checks = append(checks, checkResult{
			status: statusError, name: "Hyprland",
			detail: "hyprctl not found",
			tip:    "Hyprland is required — install it first",
		})
	} else {
		out, err := exec.Command(hyprctlPath, "version").Output()
		if err != nil {
			checks = append(checks, checkResult{
				status: statusWarn, name: "Hyprland",
				detail: "not responding (outside a Hyprland session?)",
			})
		} else {
			first := strings.TrimSpace(strings.SplitN(string(out), "\n", 2)[0])
			if first == "" {
				first = hyprctlPath
			} else if w := strings.Fields(first); len(w) > 1 {
				first = w[0] + " " + w[1]
			}
			checks = append(checks, checkResult{
				status: statusOK, name: "Hyprland", detail: first,
			})
		}
	}

	// Config symlinks: ~/.config/<app> must point into the repo
	for _, c := range []struct{ name, path string }{
		{"hypr", filepath.Join(home, ".config", "hypr")},
		{"quickshell", filepath.Join(home, ".config", "quickshell")},
		{"rain", filepath.Join(home, ".config", "rain")},
	} {
		target, isLink := symlinkInfo(c.path)
		if isLink {
			checks = append(checks, checkResult{
				status: statusOK, name: c.name + " config",
				detail: "→ " + target,
			})
		} else {
			checks = append(checks, checkResult{
				status: statusError, name: c.name + " config",
				detail: "not a symlink",
				tip:    "run `bin/dev up` to link rain/config/* → ~/.config/*",
			})
		}
	}

	// Binaries used by the shell
	tools := []struct {
		name    string
		purpose string
		install string
		require bool
	}{
		{"quickshell", "the rain shell", "quickshell project", true},
		{"qs", "quickshell IPC", "comes with quickshell", true},
		{"awww", "wallpaper daemon", "awww project", false},
		{"hyprlock", "lock screen", "hyprlock project", false},
		{"hypridle", "idle daemon", "hypridle project", false},
	}
	for _, t := range tools {
		if p, ok := lookPath(t.name); ok {
			checks = append(checks, checkResult{
				status: statusOK, name: t.name, detail: p,
			})
		} else if t.require {
			checks = append(checks, checkResult{
				status: statusError, name: t.name,
				detail: "not installed",
				tip:    "install " + t.install + " (used by the shell)",
			})
		} else {
			checks = append(checks, checkResult{
				status: statusWarn, name: t.name,
				detail: "not installed",
				tip:    "optional: install " + t.install,
			})
		}
	}

	// Running shell instance
	if _, ok := lookPath("pgrep"); ok {
		out, err := exec.Command("pgrep", "-x", "quickshell").Output()
		if err == nil && strings.TrimSpace(string(out)) != "" {
			checks = append(checks, checkResult{
				status: statusOK, name: "Rain shell", detail: "running (pid " + strings.TrimSpace(string(out)) + ")",
			})
		} else {
			checks = append(checks, checkResult{
				status: statusWarn, name: "Rain shell",
				detail: "not running",
				tip:    "launch with `rain shell`",
			})
		}
	}

	return checks
}

func lookPath(name string) (string, bool) {
	p, err := exec.LookPath(name)
	return p, err == nil
}

func symlinkInfo(path string) (string, bool) {
	fi, err := os.Lstat(path)
	if err != nil || fi.Mode()&os.ModeSymlink == 0 {
		return "", false
	}
	t, err := os.Readlink(path)
	return t, err == nil
}

func checkTTY() {
	if fi, err := os.Stdout.Stat(); err != nil || fi.Mode()&os.ModeCharDevice == 0 {
		colorGreen = ""
		colorYellow = ""
		colorRed = ""
		colorReset = ""
	}
}
