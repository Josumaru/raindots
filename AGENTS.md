# Raindots — Hyprland Dotfiles

Personal Hyprland dotfiles managed via symlinks. The repo is the source of truth; deployment is one-way: repo → `~/.config/`.

## Before answering, load relevant skills

When the user asks about a topic that matches a skill's description, load it first. Available skills:

- **hyprland** (`.agents/skills/hyprland/`) — Hyprland config syntax, hyprctl, window rules, monitors, keybinds, ecosystem tools (hyprlock, hypridle, etc.). Load this via `skill name=hyprland` whenever the user asks about Hyprland configuration or troubleshooting.

## Structure

```
raindots/
├── bin/dev           # dev workflow: up|check|hyprland|shell|logs|kill
├── install.sh        # create symlinks: rain/config/* → ~/.config/*
├── rain/
│   ├── config/
│   │   ├── hypr/           # → ~/.config/hypr
│   │   │   ├── custom/     # user overrides, not overwritten by base updates
│   │   │   ├── hyprland/   # Lua modules (env, keybinds, rules, execs, etc.)
│   │   │   ├── hypridle.conf
│   │   │   ├── hyprlock.conf
│   │   │   └── hyprland.lua    # entry point
│   │   └── quickshell/
│   │       └── rain/       # named config: quickshell -c rain
│   │           ├── shell.qml       # entry point (ii-style ShellRoot)
│   │           ├── GlobalStates.qml     # shared toggle states (bar, sidebar, lock, etc.)
│   │           ├── ReloadPopup.qml      # reload success/fail popup
│   │           ├── welcome.qml          # first-run welcome app
│   │           ├── settings.qml         # settings app
│   │           ├── killDialog.qml       # conflict killer dialog
│   │           ├── Singletons/          # shell-wide singletons (Config, Theme, Directories, etc.)
│   │           ├── assets/              # default wallpaper, SVG icons (fluent set)
│   │           ├── scripts/             # shell scripts (wallpaper, colors, keyring, etc.)
│   │           ├── translations/        # i18n JSON files
│   │           ├── defaults/            # default AI prompts
│   │           ├── panelFamilies/
│   │           │   ├── PanelLoader.qml  # LazyLoader wrapper (checks Config.ready)
│   │           │   └── RainFamily.qml   # Scope loading all ii modules
│   │           ├── services/            # 48+ services (Audio, Battery, Network, Notifications, Ai, etc.)
│   │           ├── modules/
│   │           │   ├── common/          # shared widgets, functions, models, panels
│   │           │   ├── ii/              # ii panel family modules (21 subdirectories)
│   │           │   │   ├── bar/         # pill bar (workspaces, media, clock, battery, sys tray, etc.)
│   │           │   │   ├── background/  # wallpaper background
│   │           │   │   ├── lock/        # lock screen (PAM auth, fingerprint)
│   │           │   │   ├── sidebarLeft/ # AI chat, anime/booru, translator
│   │           │   │   ├── sidebarRight/# control center, calendar, notifications, pomodoro, todo, volume, bluetooth, wifi
│   │           │   │   ├── screenCorners/   # hover-to-open sidebar via screen corners
│   │           │   │   ├── wallpaperPicker/ # full wallpaper picker GUI
│   │           │   │   ├── wallpaperSelector/# lightweight wallpaper browser
│   │           │   │   ├── sessionScreen/   # power/session (lock, logout, suspend, reboot)
│   │           │   │   ├── cheatsheet/      # keybind cheatsheet
│   │           │   │   ├── dock/            # app dock
│   │           │   │   ├── mediaControls/   # media player popup
│   │           │   │   ├── notificationPopup/ # notification popup
│   │           │   │   ├── onScreenDisplay/ # OSD (brightness, volume)
│   │           │   │   ├── onScreenKeyboard/ # virtual keyboard
│   │           │   │   ├── overlay/         # widget overlay system
│   │           │   │   ├── overview/        # app/search overview
│   │           │   │   ├── polkit/          # polkit authentication
│   │           │   │   ├── regionSelector/  # screenshot region selection
│   │           │   │   ├── screenTranslator/# screen text translator
│   │           │   │   └── verticalBar/     # vertical bar variant
│   │           │   └── settings/        # settings app pages (8 pages)
│   │           └── Singletons/   # registered singletons (Config, Theme, Directories, etc.)
│   ├── cli/                # rain CLI (Go binary)
│   │   ├── main.go         # CLI dispatch + IPC commands
│   │   └── hub.go          # hub settings backend (themes, cursors, hyprctl config)
│   ├── hub/                # settings hub QML
│   └── bin/                # → ~/.config/rain/bin (rain CLI binary)
├── docs/                   # personal notes
└── references/             # read-only reference projects (ii, ryoku-arch, etc.)
```

## Key patterns

- **Symlinks, not copies.** `install.sh` backs up existing dirs, then `ln -sfn` from `rain/config/*` to `~/.config/*`. Edit in repo, changes are live.
- **Hyprland is Lua.** One concern per file under `rain/config/hypr/hyprland/`. Custom overrides in `rain/config/hypr/custom/` are loaded after base modules.
- **Quickshell is a named config (`rain`).** Launch via `quickshell -c rain` or `quickshell -p rain/config/quickshell/rain/shell.qml`.

## Development workflow

| Command | What it does |
|---|---|
| `bin/dev up` | Re-symlink all configs + rebuild rain CLI |
| `bin/dev check` | Verify symlink status |
| `bin/dev hyprland [opts]` | Launch Hyprland with repo config (`--config` flag) |
| `bin/dev shell [name]` | Launch quickshell (default: `rain`) |
| `bin/dev shell rain -vv` | Launch with verbose logging |
| `bin/dev shell rain --debug 9999` | Launch with QML debugger |
| `bin/dev logs -f` | Follow quickshell logs |
| `bin/dev kill` | Kill quickshell instances |
| `bin/dev rain <cmd>` | Run rain CLI (wrapper) |

## Rain CLI

The `rain` binary (`rain/bin/rain`) is a Go CLI that controls Hyprland & Quickshell. All IPC commands are mapped to `IpcHandler` targets in the shell modules.

| Command | Effect |
|---|---|
| `rain shell` | Launch quickshell rain |
| `rain shell kill` | Kill quickshell |
| `rain shell reload` | Kill quickshell (reloads on next launch) |
| `rain shell log` | Follow quickshell logs |

**Shell features (IPC to QML):**
| Command | IPC target | Effect |
|---|---|---|
| `rain control` | `bar:controlCenter` | Toggle control center |
| `rain battery` | `bar:battery` | Toggle battery popup |
| `rain network` | `bar:network` | Toggle network popup |
| `rain notifications` | `bar:notifications` | Toggle notifications popup |
| `rain sidebar` | `sidebarRight:toggle` | Toggle right sidebar (control center) |
| `rain sidebarleft` | `sidebarLeft:toggle` | Toggle left sidebar (AI/booru/translator) |
| `rain search` | `search:toggle` | Toggle search/overview |
| `rain cheatsheet` | `cheatsheet:toggle` | Toggle keybind cheatsheet |
| `rain media` | `mediaControls:toggle` | Toggle media controls |
| `rain overlay` | `overlay:toggle` | Toggle widget overlay |
| `rain screenshot` | `region:screenshot` | Region screenshot |
| `rain translator` | `screenTranslator:translate` | Screen translator |
| `rain session` | `session:toggle` | Toggle session/power screen |
| `rain wallpaperpicker` | `wallpaperPicker:toggle` | Toggle wallpaper picker |
| `rain wallpaperselector` | `wallpaperSelector:toggle` | Toggle wallpaper selector |
| `rain osk` | `osk:toggle` | Toggle on-screen keyboard |
| `rain osd` | `osdVolume:trigger` | Trigger volume OSD |
| `rain bartoggle` | `bar:toggle` | Toggle bar visibility |
| `rain ipc <target> <fn>` | raw IPC | Raw quickshell IPC call |

**System commands:**
| Command | Effect |
|---|---|
| `rain workspace <n>` | Switch Hyprland workspace |
| `rain wallpaper <path>` | Set wallpaper via awww |
| `rain lock` | Lock screen (hyprlock) |
| `rain hyprctl <args>` | Run hyprctl |
| `rain hub` | Launch settings hub |
| `rain hub hypr themes` | List Hyprland themes |
| `rain hub hypr theme <slug>` | Apply a theme |
| `rain hub hypr scheme <mode>` | Set colour scheme (follow/light/dark) |
| `rain hub hypr cursors` | List cursor themes |
| `rain log` | Follow quickshell logs |

## Panel families (ii-style)

`shell.qml` uses `PanelFamilyLoader` (a `LazyLoader` wrapper) that activates when `Config.ready && panelFamily === identifier`:

```qml
component PanelFamilyLoader: LazyLoader {
    required property string identifier
    property bool extraCondition: true
    active: Config.ready && Config.options.panelFamily === identifier && extraCondition
}

PanelFamilyLoader {
    identifier: "ii"
    component: RainFamily {}
}
```

`RainFamily.qml` is a `Scope` containing all ii modules as `PanelLoader` instances:

```qml
PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }
PanelLoader { component: Background {} }
PanelLoader { component: Cheatsheet {} }
PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
PanelLoader { component: Lock {} }
// ... etc
```

To add a new panel family, create `FooFamily.qml` in `panelFamilies/` and add a `PanelFamilyLoader` for it in `shell.qml`.

## IPC handlers

Each ii module registers its own `IpcHandler` with a target matching its name. The CLI dispatches via `qs -c rain ipc call <target> <function>`. Module-level handlers:

| Target | Functions | Module |
|---|---|---|
| `bar` | toggle, close, open | bar/Bar.qml |
| `sidebarRight` | toggle, close, open | sidebarRight/SidebarRight.qml |
| `sidebarLeft` | toggle, close, open | sidebarLeft/SidebarLeft.qml |
| `search` | toggle | overview/Overview.qml |
| `cheatsheet` | toggle | cheatsheet/Cheatsheet.qml |
| `mediaControls` | toggle | mediaControls/MediaControls.qml |
| `osdVolume` | trigger | onScreenDisplay/OnScreenDisplay.qml |
| `osk` | toggle | onScreenKeyboard/OnScreenKeyboard.qml |
| `overlay` | toggle | overlay/Overlay.qml |
| `region` | screenshot | regionSelector/RegionSelector.qml |
| `screenTranslator` | translate | screenTranslator/ScreenTranslator.qml |
| `session` | toggle | sessionScreen/SessionScreen.qml |
| `wallpaperPicker` | toggle | wallpaperPickerLauncher/WallpaperPickerLauncher.qml |
| `wallpaperSelector` | toggle | wallpaperSelector/WallpaperSelector.qml |

## Bar Components (ii pill bar)

The pill bar (`modules/ii/bar/Bar.qml`) provides:
- **Workspaces** — scrollable, app icons, numbered/lettered Japanese labels
- **Active window** — window title display
- **Clock** — time with popup calendar/todo
- **Media** — now-playing with MPRIS
- **Battery** — percentage with popup (charge rate, health)
- **Resources** — RAM/Swap/CPU with popup
- **System tray** — pinned/unpinned items, context menus
- **Util buttons** — screenshot, record, color picker, mic, dark mode, performance profile
- **Weather** — bar widget + popup
- **Keyboard layout** — XKB layout indicator
- **Notification unread count** — bell with badge
- **Screen corners** — hover-to-open sidebar (configurable per corner)
- **IPC handlers** — `bar:toggle/close/open`

## Icons

This shell uses the ii icon system:
- **Fluent UI SVG icons** at `assets/icons/fluent/` (231 icons)
- **Symbolic SVG icons** at `assets/icons/` (distro logos, AI, etc.)
- **`qs.modules.common.widgets`** provides `MaterialSymbol` for Material Symbols font
- For the hub/settings app, `hub/Icon.qml` provides named SVG path icons

## Shell entry point initialization

On startup, `shell.qml` runs:
- `MaterialThemeLoader.reapplyTheme()` — apply Material3 colors
- `Hyprsunset.load()` — load night light state
- `FirstRunExperience.load()` — first-run welcome
- `ConflictKiller.load()` — detect conflicting daemons
- `Cliphist.refresh()` — load clipboard history
- `Wallpapers.load()` — load wallpaper library
- `Updates.load()` — start update checker

## Binary path conventions

Jangan pernah hardcode `"rain"` sebagai nama binary. Gunakan `Directories.rainBin` yang membaca dari env `$RAIN_BIN` (fallback `"rain"`):

```qml
import "Singletons"
Quickshell.execDetached([Directories.rainBin, "launcher"])
```

## Conventions

- Edit files in `rain/config/<app>/`, never edit inside `~/.config/` directly.
- If a live tweak is needed, make it in the repo and re-symlink (`bin/dev up`).
- Keep `custom/` for machine-specific overrides (e.g. monitor-specific keybinds, env vars).
- One concern per file — split Lua modules and QML components, don't pile unrelated logic.
- `reference/` is read-only; don't modify it.
- Untuk hub settings yang tidak bisa import Singletons shell, tetap follow pola yang sama via env atau module Directories masing-masing.
