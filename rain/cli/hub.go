package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// --- Theme types ------------------------------------------------------------

type ThemeFile struct {
	Name       string          `json:"name"`
	Blurb      string          `json:"blurb"`
	Summary    string          `json:"summary"`
	Tags       []string        `json:"tags"`
	Accent     string          `json:"accent"`
	Swatch     []string        `json:"swatch"`
	HasPalette bool            `json:"hasPalette"`
	Look       json.RawMessage `json:"look"`
}

type ThemeListItem struct {
	Slug    string   `json:"slug"`
	Name    string   `json:"name"`
	Blurb   string   `json:"blurb"`
	Summary string   `json:"summary"`
	Tags    []string `json:"tags"`
	Accent  string   `json:"accent"`
	Swatch  []string `json:"swatch"`
	Active  bool     `json:"active"`
}

type ThemesResponse struct {
	FollowWallpaper bool            `json:"followWallpaper"`
	Themes          []ThemeListItem `json:"themes"`
}

type themeState struct {
	Slug            string `json:"slug"`
	FollowWallpaper bool   `json:"followWallpaper"`
	Scheme          string `json:"scheme,omitempty"`
}

// --- Paths ------------------------------------------------------------------

func hyprConfigDir() string {
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(base, "hypr")
}

func ryokuConfigDir() string {
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(base, "ryoku")
}

func themesDir() string         { return filepath.Join(hyprConfigDir(), "themes") }
func themeStatePath() string    { return filepath.Join(ryokuConfigDir(), "theme.json") }
func generatedLuaPath() string  { return filepath.Join(hyprConfigDir(), "settings.lua") }

func wallustCacheDir() string {
	base := os.Getenv("XDG_CACHE_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".cache")
	}
	return filepath.Join(base, "wallust")
}

// --- Theme state ------------------------------------------------------------

func loadThemeState() themeState {
	s := themeState{FollowWallpaper: true} // default: follow wallpaper
	if b, err := os.ReadFile(themeStatePath()); err == nil {
		_ = json.Unmarshal(b, &s)
	}
	return s
}

func saveThemeState(s themeState) {
	_ = atomicWrite(themeStatePath(), mustJSON(s), 0o644)
}

func loadThemeFile(slug string) (ThemeFile, error) {
	var t ThemeFile
	b, err := os.ReadFile(filepath.Join(themesDir(), slug, "theme.json"))
	if err != nil {
		return t, err
	}
	return t, json.Unmarshal(b, &t)
}

// --- Theme listing & applying -----------------------------------------------

func cmdHubThemes() error {
	st := loadThemeState()
	entries, _ := os.ReadDir(themesDir())
	items := []ThemeListItem{}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		t, err := loadThemeFile(e.Name())
		if err != nil {
			continue
		}
		items = append(items, ThemeListItem{
			Slug: e.Name(), Name: t.Name, Blurb: t.Blurb, Summary: t.Summary,
			Tags: t.Tags, Accent: t.Accent, Swatch: t.Swatch, Active: e.Name() == st.Slug,
		})
	}
	sort.Slice(items, func(i, j int) bool { return items[i].Name < items[j].Name })
	return printJSON(ThemesResponse{FollowWallpaper: st.FollowWallpaper, Themes: items})
}

func cmdHubApplyTheme(slug string) error {
	dir := filepath.Join(themesDir(), slug)
	tf, err := loadThemeFile(slug)
	if err != nil {
		return fmt.Errorf("theme %q: %w", slug, err)
	}

	// Apply look via hyprctl live
	if len(tf.Look) > 0 {
		var look struct {
			Rounding      int     `json:"rounding"`
			GapsIn        int     `json:"gapsIn"`
			GapsOut       int     `json:"gapsOut"`
			BorderSize    int     `json:"borderSize"`
			ActiveOpacity float64 `json:"activeOpacity"`
		}
		_ = json.Unmarshal(tf.Look, &look)
		if look.Rounding > 0 {
			_ = exec.Command("hyprctl", "keyword", "decoration:rounding", fmt.Sprintf("%d", look.Rounding)).Run()
		}
		if look.GapsIn > 0 {
			_ = exec.Command("hyprctl", "keyword", "general:gaps_in", fmt.Sprintf("%d", look.GapsIn)).Run()
		}
		if look.GapsOut > 0 {
			_ = exec.Command("hyprctl", "keyword", "general:gaps_out", fmt.Sprintf("%d", look.GapsOut)).Run()
		}
		if look.BorderSize > 0 {
			_ = exec.Command("hyprctl", "keyword", "general:border_size", fmt.Sprintf("%d", look.BorderSize)).Run()
		}
		if look.ActiveOpacity > 0 {
			_ = exec.Command("hyprctl", "keyword", "decoration:active_opacity", fmt.Sprintf("%.2f", look.ActiveOpacity)).Run()
		}
	}

	// Copy init.lua if present
	initPath := filepath.Join(dir, "init.lua")
	if init, err := os.ReadFile(initPath); err == nil {
		_ = atomicWrite(filepath.Join(hyprConfigDir(), "theme.lua"), init, 0o644)
	}

	// Update state
	st := loadThemeState()
	st.Slug = slug
	saveThemeState(st)

	// Apply palette
	if !st.FollowWallpaper && tf.HasPalette {
		if pal, err := loadPalette(filepath.Join(dir, "colors.json")); err == nil {
			writePalette(pal)
		}
	}

	_ = exec.Command("hyprctl", "reload").Run()
	return nil
}

// --- Colour scheme ----------------------------------------------------------

func cmdHubScheme(mode string) error {
	st := loadThemeState()
	switch mode {
	case "follow":
		st.Scheme = ""
		st.FollowWallpaper = true
		saveThemeState(st)
		// Re-paint from wallpaper
		_ = exec.Command("pkill", "-USR1", "-x", "wallust").Run()
	case "light", "dark":
		st.Scheme = mode
		st.FollowWallpaper = false
		saveThemeState(st)
	case "get":
		return printJSON(map[string]string{"scheme": currentScheme()})
	default:
		return fmt.Errorf("unknown scheme %q (want follow|light|dark)", mode)
	}
	_ = exec.Command("hyprctl", "reload").Run()
	return nil
}

func currentScheme() string {
	st := loadThemeState()
	if st.FollowWallpaper {
		return "follow"
	}
	if st.Scheme != "" {
		return st.Scheme
	}
	return "dark"
}

// --- Cursor themes ----------------------------------------------------------

func cmdHubCursors() error {
	seen := map[string]bool{}
	for _, dir := range iconSearchDirs() {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, e := range entries {
			if !e.IsDir() {
				continue
			}
			if _, err := os.Stat(filepath.Join(dir, e.Name(), "cursors")); err == nil {
				seen[e.Name()] = true
			}
		}
	}
	out := make([]string, 0, len(seen))
	for n := range seen {
		out = append(out, n)
	}
	sort.Strings(out)
	return printJSON(out)
}

func iconSearchDirs() []string {
	home := os.Getenv("HOME")
	dataHome := os.Getenv("XDG_DATA_HOME")
	if dataHome == "" {
		dataHome = filepath.Join(home, ".local", "share")
	}
	return []string{
		filepath.Join(home, ".icons"),
		filepath.Join(dataHome, "icons"),
		"/usr/share/icons",
		"/usr/local/share/icons",
	}
}

// --- Palette helpers --------------------------------------------------------

func loadPalette(path string) (map[string]string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var m map[string]string
	if err := json.Unmarshal(b, &m); err != nil {
		return nil, err
	}
	return m, nil
}

func writePalette(pal map[string]string) {
	_ = os.MkdirAll(wallustCacheDir(), 0o755)
	_ = atomicWrite(filepath.Join(wallustCacheDir(), "colors.json"), mustJSON(pal), 0o644)
}

// --- Lua generation ---------------------------------------------------------

const settingsLuaHeader = `-- Generated by Rain Settings. Do not edit by hand.
-- Loaded by hyprland.lua before shellOverrides.

`

func cmdHubWriteSettings(jsonData string) error {
	var cfg struct {
		GapsIn     int     `json:"gapsIn"`
		GapsOut    int     `json:"gapsOut"`
		BorderSize int     `json:"borderSize"`
		Rounding   int     `json:"rounding"`
		ActiveOp   float64 `json:"activeOpacity"`
		InactiveOp float64 `json:"inactiveOpacity"`
		BlurSize   int     `json:"blurSize"`
		BlurPasses int     `json:"blurPasses"`
	}
	if err := json.Unmarshal([]byte(jsonData), &cfg); err != nil {
		return err
	}

	var sections []string
	sections = append(sections, fmt.Sprintf("gaps_in = %d", cfg.GapsIn))
	sections = append(sections, fmt.Sprintf("gaps_out = %d", cfg.GapsOut))
	sections = append(sections, fmt.Sprintf("border_size = %d", cfg.BorderSize))
	sections = append(sections, fmt.Sprintf("rounding = %d", cfg.Rounding))
	sections = append(sections, fmt.Sprintf("active_opacity = %s", luaNum(cfg.ActiveOp)))
	sections = append(sections, fmt.Sprintf("inactive_opacity = %s", luaNum(cfg.InactiveOp)))

	var blur []string
	blur = append(blur, fmt.Sprintf("size = %d", cfg.BlurSize))
	blur = append(blur, fmt.Sprintf("passes = %d", cfg.BlurPasses))

	lua := settingsLuaHeader
	lua += "hl.config({\n"
	lua += "  decoration = { " + strings.Join(sections, ", ") + ", blur = { " + strings.Join(blur, ", ") + " } },\n"
	lua += "})\n"

	return atomicWrite(generatedLuaPath(), []byte(lua), 0o644)
}

// --- Runner dispatch --------------------------------------------------------

func cmdHub(args []string) error {
	if len(args) == 0 {
		// Launch hub Quickshell app (qs -c hub loads hub/shell.qml)
		runCmd("qs", "-c", "hub")
		return nil
	}

	switch args[0] {
	case "hypr":
		return cmdHubHypr(args[1:])
	case "config":
		return cmdHubConfig(args[1:])
	case "cursors":
		return cmdHubCursors()
	default:
		return fmt.Errorf("hub: unknown subcommand %q (try hypr|config|cursors)", args[0])
	}
}

func cmdHubHypr(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("hub hypr: need a subcommand")
	}

	switch args[0] {
	case "themes":
		return cmdHubThemes()
	case "theme":
		if len(args) < 2 {
			return fmt.Errorf("hub hypr theme <slug>")
		}
		return cmdHubApplyTheme(args[1])
	case "scheme":
		if len(args) < 2 {
			return currentSchemeReport()
		}
		return cmdHubScheme(args[1])
	case "cursors":
		return cmdHubCursors()
	case "layouts":
		return cmdHubLayouts()
	case "variants":
		if len(args) < 2 {
			return fmt.Errorf("hub hypr variants <layout>")
		}
		return cmdHubVariants(args[1])
	case "get":
		return cmdHubHyprGet()
	case "defaults":
		return cmdHubHyprDefaults()
	case "preview":
		if len(args) < 2 {
			return fmt.Errorf("hub hypr preview <json>")
		}
		return cmdHubHyprPreview(args[1])
	case "save":
		if len(args) < 2 {
			return fmt.Errorf("hub hypr save <json>")
		}
		return cmdHubHyprSave(args[1])
	case "restore":
		return cmdHubHyprRestore()
	case "keybinds":
		return cmdHubHyprKeybinds()
	default:
		return fmt.Errorf("hub hypr: unknown subcommand %q", args[0])
	}
}

// --- XKB layouts ---------------------------------------------------------------

func cmdHubLayouts() error {
	out, err := exec.Command("localectl", "list-x11-keymap-layouts").Output()
	if err != nil {
		return fmt.Errorf("list layouts: %w", err)
	}
	var items []map[string]string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		items = append(items, map[string]string{
			"code": line,
			"name": line,
		})
	}
	return printJSON(items)
}

func cmdHubVariants(layout string) error {
	out, err := exec.Command("localectl", "list-x11-keymap-variants", layout).Output()
	if err != nil {
		// no variants = not an error, return empty
		return printJSON([]map[string]string{})
	}
	var items []map[string]string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		// line format: "code  name"
		parts := strings.SplitN(line, " ", 2)
		code := parts[0]
		name := line
		if len(parts) > 1 {
			name = strings.TrimSpace(parts[1])
		}
		items = append(items, map[string]string{
			"code": code,
			"name": name,
		})
	}
	return printJSON(items)
}

// --- Hyprland settings backend -------------------------------------------------

func cmdHubHyprGet() error {
	doc := defaultHyprDoc()
	// Apply overrides from settings.lua if it exists
	if b, err := os.ReadFile(generatedLuaPath()); err == nil {
		_ = parseOverrides(string(b), &doc)
	}
	return printJSON(doc)
}

func cmdHubHyprDefaults() error {
	return printJSON(defaultHyprDoc())
}

func cmdHubHyprPreview(jsonStr string) error {
	var doc HyprDoc
	if err := json.Unmarshal([]byte(jsonStr), &doc); err != nil {
		return fmt.Errorf("preview: invalid json: %w", err)
	}
	return applyToHyprctl(doc)
}

func cmdHubHyprSave(jsonStr string) error {
	var doc HyprDoc
	if err := json.Unmarshal([]byte(jsonStr), &doc); err != nil {
		return fmt.Errorf("save: invalid json: %w", err)
	}
	lua := doc.toLua()
	if err := atomicWrite(generatedLuaPath(), []byte(lua), 0o644); err != nil {
		return fmt.Errorf("save: write: %w", err)
	}
	return exec.Command("hyprctl", "reload").Run()
}

func cmdHubHyprRestore() error {
	return exec.Command("hyprctl", "reload").Run()
}

// --- Keybinds ------------------------------------------------------------------

func cmdHubHyprKeybinds() error {
	cats := []map[string]any{
		{
			"name": "Window management",
			"binds": []map[string]any{
				{"keys": []string{"SUPER", "Q"}, "desc": "Close focused window"},
				{"keys": []string{"SUPER", "W"}, "desc": "Toggle float"},
				{"keys": []string{"SUPER", "F"}, "desc": "Toggle fullscreen"},
				{"keys": []string{"SUPER", "V"}, "desc": "Toggle split"},
				{"keys": []string{"SUPER", "M"}, "desc": "Toggle maximize"},
				{"keys": []string{"SUPER", "P"}, "desc": "Pin window (keep above)"},
			},
		},
		{
			"name": "Workspace navigation",
			"binds": []map[string]any{
				{"keys": []string{"SUPER", "1-9"}, "desc": "Switch to workspace"},
				{"keys": []string{"SUPER", "SHIFT", "1-9"}, "desc": "Move to workspace"},
				{"keys": []string{"SUPER", "TAB"}, "desc": "Next workspace"},
				{"keys": []string{"SUPER", "SHIFT", "TAB"}, "desc": "Prev workspace"},
				{"keys": []string{"SUPER", "mouse_down"}, "desc": "Next workspace (scroll)"},
				{"keys": []string{"SUPER", "mouse_up"}, "desc": "Prev workspace (scroll)"},
			},
		},
		{
			"name": "Launcher & search",
			"binds": []map[string]any{
				{"keys": []string{"SUPER", "SPACE"}, "desc": "App launcher (fuzzel)"},
				{"keys": []string{"SUPER", "SHIFT", "ESCAPE"}, "desc": "Clipboard manager"},
			},
		},
		{
			"name": "System",
			"binds": []map[string]any{
				{"keys": []string{"SUPER", "L"}, "desc": "Lock screen"},
				{"keys": []string{"SUPER", "SHIFT", "S"}, "desc": "Screenshot"},
				{"keys": []string{"SUPER", "SHIFT", "R"}, "desc": "Screenshot area"},
				{"keys": []string{"SUPER", "ESCAPE"}, "desc": "Logout menu"},
			},
		},
		{
			"name": "Media & volume",
			"binds": []map[string]any{
				{"keys": []string{"XF86AudioRaiseVolume"}, "desc": "Volume up"},
				{"keys": []string{"XF86AudioLowerVolume"}, "desc": "Volume down"},
				{"keys": []string{"XF86AudioMute"}, "desc": "Mute toggle"},
				{"keys": []string{"XF86AudioPlay"}, "desc": "Play/Pause"},
				{"keys": []string{"XF86AudioNext"}, "desc": "Next track"},
				{"keys": []string{"XF86AudioPrev"}, "desc": "Previous track"},
			},
		},
	}
	// Try to read custom keybinds from binds.lua and merge
	_ = parseKeybinds(cats)
	return printJSON(cats)
}

// --- Config storage (hub settings TOML) ---------------------------------------

const hubConfigBase = "rain"

func hubConfigPath() string {
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		base = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(base, hubConfigBase, "hub.json")
}

func loadHubConfig() map[string]string {
	m := map[string]string{
		"update_interval": "daily",
	}
	if b, err := os.ReadFile(hubConfigPath()); err == nil {
		var loaded map[string]string
		if json.Unmarshal(b, &loaded) == nil {
			for k, v := range loaded {
				m[k] = v
			}
		}
	}
	return m
}

func saveHubConfig(m map[string]string) error {
	_ = os.MkdirAll(filepath.Dir(hubConfigPath()), 0o755)
	return atomicWrite(hubConfigPath(), mustJSON(m), 0o644)
}

func cmdHubConfig(args []string) error {
	if len(args) == 0 {
		return printJSON(loadHubConfig())
	}
	switch args[0] {
	case "get":
		if len(args) < 2 {
			return fmt.Errorf("hub config get <key>")
		}
		cfg := loadHubConfig()
		fmt.Println(cfg[args[1]])
		return nil
	case "set":
		if len(args) < 3 {
			return fmt.Errorf("hub config set <key> <value>")
		}
		cfg := loadHubConfig()
		cfg[args[1]] = args[2]
		return saveHubConfig(cfg)
	default:
		return fmt.Errorf("hub config: unknown subcommand %q", args[0])
	}
}

func parseKeybinds(cats []map[string]any) error {
	// Read custom binds from keybinds.lua or settings.lua
	// Currently just returns the hardcoded set — custom overrides
	// are managed through the HyprStore in the hub UI.
	return nil
}

// --- HyprDoc used by the settings backend --------------------------------------

type HyprDoc struct {
	Appearance HyprAppearance `json:"appearance"`
	Input      HyprInput      `json:"input"`
	Cursor     HyprCursor     `json:"cursor"`
	Env        []any          `json:"env"`
	WindowRules []any         `json:"windowRules"`
	LayerRules  []any         `json:"layerRules"`
	Autostart  []HyprAutostart `json:"autostart"`
	Keybinds   []HyprKeybind   `json:"keybinds"`
	Anim       HyprAnim        `json:"anim"`
}

type HyprAppearance struct {
	GapsIn          int     `json:"gapsIn"`
	GapsOut         int     `json:"gapsOut"`
	BorderSize      int     `json:"borderSize"`
	Rounding        int     `json:"rounding"`
	RoundingPower   float64 `json:"roundingPower"`
	ActiveOpacity   float64 `json:"activeOpacity"`
	InactiveOpacity float64 `json:"inactiveOpacity"`
	DimInactive     bool    `json:"dimInactive"`
	DimStrength     float64 `json:"dimStrength"`
	BlurEnabled     bool    `json:"blurEnabled"`
	BlurSize        int     `json:"blurSize"`
	BlurPasses      int     `json:"blurPasses"`
	BlurXray        bool    `json:"blurXray"`
	BlurVibrancy    float64 `json:"blurVibrancy"`
	BlurNoise       float64 `json:"blurNoise"`
	ShadowEnabled   bool    `json:"shadowEnabled"`
	ShadowRange     int     `json:"shadowRange"`
	ShadowPower     int     `json:"shadowPower"`
	GlowEnabled     bool    `json:"glowEnabled"`
	GlowRange       int     `json:"glowRange"`
	GlowColor       string  `json:"glowColor"`
	Animations      bool    `json:"animations"`
	Layout          string  `json:"layout"`
	ActiveBorder    string  `json:"activeBorder"`
	InactiveBorder  string  `json:"inactiveBorder"`
	ResizeOnBorder  bool    `json:"resizeOnBorder"`
	SnapEnabled     bool    `json:"snapEnabled"`
	WobblyWindows   bool    `json:"wobblyWindows"`
	WindowStyle     string  `json:"windowStyle"`
	AnimatedBorder  bool    `json:"animatedBorder"`
	BorderAngleSpeed float64 `json:"borderAngleSpeed"`
}

type HyprInput struct {
	KbLayout          string  `json:"kbLayout"`
	KbVariant         string  `json:"kbVariant"`
	KbOptions         string  `json:"kbOptions"`
	NumlockByDefault  bool    `json:"numlockByDefault"`
	FollowMouse       int     `json:"followMouse"`
	Sensitivity       float64 `json:"sensitivity"`
	AccelProfile      string  `json:"accelProfile"`
	LeftHanded        bool    `json:"leftHanded"`
	MouseNaturalScroll bool   `json:"mouseNaturalScroll"`
	MouseScrollFactor float64 `json:"mouseScrollFactor"`
	MiddleClickPaste  bool    `json:"middleClickPaste"`
	NaturalScroll     bool    `json:"naturalScroll"`
	TapToClick        bool    `json:"tapToClick"`
	TapAndDrag        bool    `json:"tapAndDrag"`
	Clickfinger       bool    `json:"clickfinger"`
	MiddleEmulation   bool    `json:"middleEmulation"`
	TouchScrollFactor float64 `json:"touchScrollFactor"`
	DisableWhileTyping bool   `json:"disableWhileTyping"`
	RepeatRate        int     `json:"repeatRate"`
	RepeatDelay       int     `json:"repeatDelay"`
	WorkspaceSwipe    bool    `json:"workspaceSwipe"`
	SwipeFingers      int     `json:"swipeFingers"`
	SwipeInvert       bool    `json:"swipeInvert"`
	SwipeCreateNew    bool    `json:"swipeCreateNew"`
	SwipeDistance     int     `json:"swipeDistance"`
}

type HyprCursor struct {
	Theme            string `json:"theme"`
	Size             int    `json:"size"`
	InactiveTimeout  int    `json:"inactiveTimeout"`
	HideOnKeyPress   bool   `json:"hideOnKeyPress"`
}

type HyprAutostart struct {
	Command string `json:"command"`
}

type HyprKeybind struct {
	Keys   string `json:"keys"`
	Action string `json:"action"`
	Value  string `json:"value"`
}

type HyprAnim struct {
	Items  []any `json:"items"`
	Curves []any `json:"curves"`
}

func defaultHyprDoc() HyprDoc {
	return HyprDoc{
		Appearance: HyprAppearance{
			GapsIn: 12, GapsOut: 18, BorderSize: 2, Rounding: 2, RoundingPower: 4,
			ActiveOpacity: 1, InactiveOpacity: 0.94, DimInactive: false, DimStrength: 0.5,
			BlurEnabled: true, BlurSize: 4, BlurPasses: 1, BlurXray: false,
			BlurVibrancy: 0.17, BlurNoise: 0.01,
			ShadowEnabled: true, ShadowRange: 45, ShadowPower: 4,
			GlowEnabled: false, GlowRange: 10, GlowColor: "#ee33cc",
			Animations: true, Layout: "dwindle", ActiveBorder: "#e0563b",
			InactiveBorder: "#313a4d", ResizeOnBorder: true, SnapEnabled: false,
			WobblyWindows: false, WindowStyle: "pop", AnimatedBorder: false, BorderAngleSpeed: 3,
		},
		Input: HyprInput{
			KbLayout: "us", KbVariant: "", KbOptions: "", NumlockByDefault: false,
			FollowMouse: 2, Sensitivity: 0, AccelProfile: "", LeftHanded: false,
			MouseNaturalScroll: false, MouseScrollFactor: 1, MiddleClickPaste: true,
			NaturalScroll: false, TapToClick: true, TapAndDrag: true, Clickfinger: false,
			MiddleEmulation: false, TouchScrollFactor: 1, DisableWhileTyping: true,
			RepeatRate: 25, RepeatDelay: 600,
			WorkspaceSwipe: false, SwipeFingers: 3, SwipeInvert: true, SwipeCreateNew: true,
			SwipeDistance: 300,
		},
		Cursor: HyprCursor{
			Theme: "Bibata-Modern-Ice", Size: 24, InactiveTimeout: 0, HideOnKeyPress: false,
		},
		Env:        []any{},
		WindowRules: []any{},
		LayerRules:  []any{},
		Autostart:  []HyprAutostart{},
		Keybinds:   []HyprKeybind{},
		Anim:       HyprAnim{Items: []any{}, Curves: []any{}},
	}
}

func (d HyprDoc) toLua() string {
	a := d.Appearance
	i := d.Input
	var sections []string
	sections = append(sections, fmt.Sprintf("gaps_in = %d", a.GapsIn))
	sections = append(sections, fmt.Sprintf("gaps_out = %d", a.GapsOut))
	sections = append(sections, fmt.Sprintf("border_size = %d", a.BorderSize))
	sections = append(sections, fmt.Sprintf("rounding = %d", a.Rounding))
	sections = append(sections, fmt.Sprintf("active_opacity = %s", luaNum(a.ActiveOpacity)))
	sections = append(sections, fmt.Sprintf("inactive_opacity = %s", luaNum(a.InactiveOpacity)))
	sections = append(sections, fmt.Sprintf("follow_mouse = %d", i.FollowMouse))
	sections = append(sections, fmt.Sprintf("sensitivity = %s", luaNum(i.Sensitivity)))
	sections = append(sections, fmt.Sprintf("accel_profile = \"%s\"", i.AccelProfile))
	sections = append(sections, fmt.Sprintf("natural_scroll = %t", i.NaturalScroll))
	sections = append(sections, fmt.Sprintf("tap_to_click = %t", i.TapToClick))

	var blur []string
	blur = append(blur, fmt.Sprintf("size = %d", a.BlurSize))
	blur = append(blur, fmt.Sprintf("passes = %d", a.BlurPasses))

	lua := settingsLuaHeader
	lua += "hl.config({\n"
	lua += "  decoration = { " + strings.Join(sections, ", ") + ", blur = { " + strings.Join(blur, ", ") + " } },\n"
	lua += "})\n"
	return lua
}

func parseOverrides(lua string, doc *HyprDoc) error {
	// Simple parser for settings.lua (hl.config({ key = value, ... }))
	// Only extracts values we know about — unknown keys are skipped silently.
	s := strings.ReplaceAll(lua, "\n", " ")
	s = strings.ReplaceAll(s, "\t", " ")

	extractInt := func(name string, target *int) {
		re := regexp.MustCompile(name + `\s*=\s*(\d+)`)
		if m := re.FindStringSubmatch(s); len(m) > 1 {
			*target, _ = strconv.Atoi(m[1])
		}
	}
	extractFloat := func(name string, target *float64) {
		re := regexp.MustCompile(name + `\s*=\s*([0-9.]+)`)
		if m := re.FindStringSubmatch(s); len(m) > 1 {
			v, _ := strconv.ParseFloat(m[1], 64)
			*target = v
		}
	}
	extractBool := func(name string, target *bool) {
		re := regexp.MustCompile(name + `\s*=\s*(true|false)`)
		if m := re.FindStringSubmatch(s); len(m) > 1 {
			*target = m[1] == "true"
		}
	}

	extractInt("gaps_in", &doc.Appearance.GapsIn)
	extractInt("gaps_out", &doc.Appearance.GapsOut)
	extractInt("border_size", &doc.Appearance.BorderSize)
	extractInt("rounding", &doc.Appearance.Rounding)
	extractFloat("active_opacity", &doc.Appearance.ActiveOpacity)
	extractFloat("inactive_opacity", &doc.Appearance.InactiveOpacity)
	extractInt("follow_mouse", &doc.Input.FollowMouse)
	extractFloat("sensitivity", &doc.Input.Sensitivity)
	extractBool("natural_scroll", &doc.Input.NaturalScroll)
	extractBool("tap_to_click", &doc.Input.TapToClick)

	return nil
}

func applyToHyprctl(doc HyprDoc) error {
	a := doc.Appearance
	cmds := []struct{ k, v string }{
		{"general:gaps_in", fmt.Sprintf("%d", a.GapsIn)},
		{"general:gaps_out", fmt.Sprintf("%d", a.GapsOut)},
		{"general:border_size", fmt.Sprintf("%d", a.BorderSize)},
		{"decoration:rounding", fmt.Sprintf("%d", a.Rounding)},
		{"decoration:active_opacity", luaNum(a.ActiveOpacity)},
		{"decoration:inactive_opacity", luaNum(a.InactiveOpacity)},
		{"input:follow_mouse", fmt.Sprintf("%d", doc.Input.FollowMouse)},
		{"input:sensitivity", luaNum(doc.Input.Sensitivity)},
		{"input:accel_profile", doc.Input.AccelProfile},
		{"input:natural_scroll", fmt.Sprintf("%t", doc.Input.NaturalScroll)},
		{"input:tap_to_click", fmt.Sprintf("%t", doc.Input.TapToClick)},
	}
	for _, c := range cmds {
		_ = exec.Command("hyprctl", "keyword", c.k, c.v).Run()
	}
	return nil
}

func currentSchemeReport() error {
	return printJSON(map[string]string{"scheme": currentScheme()})
}

// --- Utilities --------------------------------------------------------------

func printJSON(v any) error {
	b, err := json.Marshal(v)
	if err != nil {
		return err
	}
	os.Stdout.Write(b)
	fmt.Println()
	return nil
}

func mustJSON(v any) []byte {
	b, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return []byte("{}")
	}
	return b
}

func atomicWrite(path string, b []byte, mode os.FileMode) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(path), ".tmp-*")
	if err != nil {
		return err
	}
	tmp := f.Name()
	if _, err := f.Write(b); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Chmod(mode); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(tmp)
		return err
	}
	return os.Rename(tmp, path)
}

func luaNum(f float64) string {
	s := fmt.Sprintf("%g", f)
	if !strings.ContainsAny(s, ".eE") {
		s += ".0"
	}
	return s
}
