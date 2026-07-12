package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const qsConfig = "rain"

var commands = map[string]string{
	"control":           "bar:controlCenter",
	"controlcenter":     "bar:controlCenter",
	"battery":           "bar:battery",
	"network":           "bar:network",
	"notifications":     "bar:notifications",
	"sidebar":           "sidebarRight:toggle",
	"sidebarright":      "sidebarRight:toggle",
	"sidebarleft":       "sidebarLeft:toggle",
	"sidebaropen":       "sidebarRight:open",
	"sidebarclose":      "sidebarRight:close",
	"sidebarleftopen":   "sidebarLeft:open",
	"sidebarleftclose":  "sidebarLeft:close",
	"search":            "search:toggle",
	"overview":          "search:toggle",
	"cheatsheet":        "cheatsheet:toggle",
	"media":             "mediaControls:toggle",
	"mediacontrols":     "mediaControls:toggle",
	"overlay":           "overlay:toggle",
	"region":            "region:screenshot",
	"screenshot":        "region:screenshot",
	"translator":        "screenTranslator:translate",
	"screentranslator":  "screenTranslator:translate",
	"session":           "session:toggle",
	"wallpaperpicker":   "wallpaperPicker:toggle",
	"wallpaperselector": "wallpaperSelector:toggle",
	"osk":               "osk:toggle",
	"keyboard":          "osk:toggle",
	"osd":               "osdVolume:trigger",
	"bartoggle":         "bar:toggle",
	"barclose":          "bar:close",
	"baropen":           "bar:open",
}

func main() {
	if len(os.Args) < 2 {
		usage()
	}

	cmd := os.Args[1]
	args := os.Args[2:]

	switch cmd {
	case "shell":
		cmdShell(args)
	case "workspace", "ws":
		cmdWorkspace(args)
	case "hyprctl":
		cmdHyprctl(args)
	case "log", "logs":
		cmdLog(args)
	case "wallpaper":
		cmdWallpaper(args)
	case "lock":
		cmdLock()
	case "hub":
		if err := cmdHub(args); err != nil {
			fmt.Fprintln(os.Stderr, "Error:", err)
			os.Exit(1)
		}
	case "status":
		cmdStatus(args)
	case "ipc":
		cmdIpc(args)
	case "help", "--help", "-h":
		usage()
	default:
		if target, ok := commands[cmd]; ok {
			ipcCall(target, args)
		} else {
			usage()
		}
	}
}

func usage() {
	fmt.Fprintf(os.Stderr, `Rain CLI — Control Hyprland & Quickshell

Usage:
  rain shell                     Launch quickshell rain
  rain shell kill                Kill running quickshell
  rain shell reload              Reload quickshell
  rain shell log                 Follow quickshell logs
  rain control                   Toggle control center
  rain battery                   Toggle battery popup
  rain network                   Toggle network popup
  rain notifications             Toggle notifications popup
  rain workspace <n>             Switch to workspace
  rain wallpaper <path>          Set wallpaper
  rain lock                      Lock screen
  rain hub                       Launch settings hub
  rain hub hypr themes           List available themes
  rain hub hypr theme <slug>     Apply a theme
  rain hub hypr scheme <mode>    Set colour source (follow|light|dark)
  rain hub hypr cursors          List cursor themes
  rain hyprctl <args>            Run hyprctl with args
  rain log                       Show quickshell logs

  # II shell features
  rain sidebar                   Toggle right sidebar (control center)
  rain sidebarleft               Toggle left sidebar
  rain search                    Toggle search/overview
  rain cheatsheet                Toggle keybind cheatsheet
  rain media                     Toggle media controls
  rain overlay                   Toggle overlay
  rain screenshot                Take region screenshot
  rain translator                Screen translator
  rain session                   Toggle session/power screen
  rain wallpaperpicker           Toggle wallpaper picker
  rain wallpaperselector         Toggle wallpaper selector
  rain osk                       Toggle on-screen keyboard
  rain osd                       Trigger volume OSD
  rain bartoggle                 Toggle bar visibility
  rain ipc <target> <fn> [args]  Raw quickshell IPC call

`)
	os.Exit(1)
}

func qsCmd(args ...string) *exec.Cmd {
	return exec.Command("qs", args...)
}

func ipcCall(target string, args []string) {
	fullArgs := []string{"-c", qsConfig, "ipc", "call"}
	parts := strings.SplitN(target, ":", 2)
	if len(parts) == 2 {
		fullArgs = append(fullArgs, parts[0], parts[1])
	} else {
		fullArgs = append(fullArgs, target)
	}
	fullArgs = append(fullArgs, args...)
	runCmd("qs", fullArgs...)
}

func runCmd(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s %s: %v\n", name, strings.Join(args, " "), err)
		os.Exit(1)
	}
}

func cmdIpc(args []string) {
	if len(args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: rain ipc <target> <function> [args...]")
		os.Exit(1)
	}
	fullArgs := []string{"-c", qsConfig, "ipc", "call"}
	fullArgs = append(fullArgs, args...)
	runCmd("qs", fullArgs...)
}

func cmdShell(args []string) {
	if len(args) > 0 {
		switch args[0] {
		case "kill":
			exec.Command("quickshell", "-c", qsConfig, "kill").Run()
		case "reload":
			exec.Command("quickshell", "-c", qsConfig, "kill").Run()
		case "log":
			args := []string{"-c", qsConfig, "log", "-vv", "--log-times", "--follow"}
			runCmd("qs", args...)
		default:
			fmt.Fprintf(os.Stderr, "Unknown shell subcommand: %s\n", args[0])
			os.Exit(1)
		}
	} else {
		runCmd("quickshell", "-c", qsConfig)
	}
}

func cmdWorkspace(args []string) {
	if len(args) < 1 {
		fmt.Fprintln(os.Stderr, "Usage: rain workspace <n>")
		os.Exit(1)
	}
	runCmd("hyprctl", "dispatch", "workspace", args[0])
}

func cmdHyprctl(args []string) {
	runCmd("hyprctl", args...)
}

func cmdLog(args []string) {
	follow := true
	qsArgs := []string{"-c", qsConfig, "log"}
	for _, a := range args {
		if a == "-f" || a == "--follow" {
			follow = true
		}
	}
	if follow {
		qsArgs = append(qsArgs, "-vv", "--log-times", "--follow")
	}
	runCmd("qs", qsArgs...)
}

func cmdWallpaper(args []string) {
	path := ""
	if len(args) > 0 {
		path = args[0]
		if !strings.HasPrefix(path, "/") {
			path = filepath.Join(os.Getenv("HOME"), path)
		}
		runCmd("awww", "img", "--transition-type", "center", "--transition-duration", "0.6", "--transition-fps", "60", path)
	} else {
		fmt.Fprintln(os.Stderr, "Usage: rain wallpaper <path>")
		os.Exit(1)
	}
}

func cmdLock() {
	ipcCall("lock", []string{"activate"})
}

func cmdStatus(args []string) {
	out := map[string]any{
		"installedVersion": "0.1.0",
		"latestVersion":    "",
		"channel":          "main",
		"pendingUpdates":   0,
		"updates":          []any{},
	}
	b, _ := json.Marshal(out)
	os.Stdout.Write(b)
	fmt.Println()
}
