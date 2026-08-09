package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"text/tabwriter"
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
		usage(os.Stderr)
		os.Exit(1)
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
	case "doctor":
		cmdDoctor(args)
	case "help", "--help", "-h":
		usage(os.Stdout)
		os.Exit(0)
	default:
		if target, ok := commands[cmd]; ok {
			ipcCall(target, args)
		} else {
			usage(os.Stderr)
			os.Exit(1)
		}
	}
}

func usage(w io.Writer) {
	tw := tabwriter.NewWriter(w, 0, 4, 2, ' ', 0)

	fmt.Fprintln(tw, "Rain CLI — Control Hyprland & Quickshell")
	fmt.Fprintln(tw)
	fmt.Fprintln(tw, "Usage:")
	fmt.Fprintf(tw, "  rain <command> [args]\n")

	section := func(title string) {
		fmt.Fprintf(tw, "\n  %s\n", title)
	}
	row := func(cmd, desc string) {
		fmt.Fprintf(tw, "  %s\t%s\n", cmd, desc)
	}

	section("Shell")
	row("shell", "Launch quickshell rain")
	row("shell kill", "Kill running quickshell")
	row("shell reload", "Kill quickshell (reloads on next launch)")
	row("shell log", "Follow quickshell logs")
	row("log", "Follow quickshell logs")

	section("Hyprland")
	row("workspace <n>", "Switch to workspace")
	row("hyprctl <args>", "Run hyprctl with args")
	row("wallpaper <path>", "Set wallpaper")
	row("lock", "Lock screen (hyprlock)")
	row("status", "Show shell update status")

	section("Hub")
	row("hub", "Launch settings hub")
	row("hub hypr themes", "List Hyprland themes")
	row("hub hypr theme <slug>", "Apply a theme")
	row("hub hypr scheme <mode>", "Set colour source (follow|light|dark)")
	row("hub hypr cursors", "List cursor themes")

	section("Bar & Panels")
	row("control", "Toggle control center")
	row("battery", "Toggle battery popup")
	row("network", "Toggle network popup")
	row("notifications", "Toggle notifications popup")
	row("sidebar", "Toggle right sidebar (control center)")
	row("sidebaropen/sidebarclose", "Open/close right sidebar")
	row("sidebarleft", "Toggle left sidebar")
	row("sidebarleftopen/sidebarleftclose", "Open/close left sidebar")
	row("bartoggle/baropen/barclose", "Toggle/open/close bar visibility")
	row("search", "Toggle search/overview")
	row("cheatsheet", "Toggle keybind cheatsheet")
	row("media", "Toggle media controls")
	row("overlay", "Toggle widget overlay")
	row("screenshot", "Take region screenshot")
	row("translator", "Screen translator")
	row("session", "Toggle session/power screen")
	row("wallpaperpicker", "Toggle wallpaper picker")
	row("wallpaperselector", "Toggle wallpaper selector")
	row("osk", "Toggle on-screen keyboard")
	row("osd", "Trigger volume OSD")

	section("Low-level")
	row("ipc <target> <fn> [args]", "Raw quickshell IPC call")
	row("doctor", "Check environment health")

	fmt.Fprintln(tw)
	fmt.Fprintln(tw, "Aliases: controlcenter, sidebarright, overview, mediacontrols, region,")
	fmt.Fprintln(tw, "         screentranslator, keyboard, ws, logs")

	tw.Flush()
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
