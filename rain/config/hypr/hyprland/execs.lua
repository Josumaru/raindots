hl.on("hyprland.start", function ()
    -- Geoclue, bar, wallpaper, awww daemon
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("~/.local/bin/rain shell")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
    hl.exec_cmd([[sleep 3 && WALL=$(jq -r '.background.wallpaperPath' $HOME/.config/illogical-impulse/config.json); if ! echo "$WALL" | grep -qiE '\.(mp4|mkv|mov|webm|avi)$'; then awww img --transition-type center --transition-duration 0.6 --transition-fps 60 "$WALL"; fi]])

    -- Core components
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard
    -- hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && ~/.local/bin/rain ipc cliphistService update'")
    -- hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && ~/.local/bin/rain ipc cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")

    -- User apps
    hl.exec_cmd("/opt/Discord/discord")
    hl.exec_cmd("vicinae server")
    hl.exec_cmd("~/Documents/app/evershot")
    hl.exec_cmd("~/.local/share/mise/installs/node/24.13.0/bin/9router")

    local plugin_path = "~/.config/hypr/hyprland/plugin/hyprglass/hyprglass.so"
    -- local plugin_path = HOME .. "~/.config/hypr/hyprland/plugin/hyprglass/hyprglass.so"
    if not hl.plugin.hyprglass then
        os.execute("hyprctl plugin load " .. plugin_path)
    end
end)
