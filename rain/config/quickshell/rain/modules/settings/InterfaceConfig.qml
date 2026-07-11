import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    SettingSection {
        width: parent.width
        title: Translation.tr("CHEAT SHEET")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Super key symbol")
            options: [
                { key: "󰖳", label: "󰖳" },
                { key: "", label: "" },
                { key: "󰨡", label: "󰨡" },
                { key: "", label: "" },
                { key: "󰌽", label: "󰌽" },
                { key: "󰣇", label: "󰣇" },
                { key: "", label: "" },
                { key: "", label: "" },
                { key: "", label: "" }
            ]
            current: Config.options.cheatsheet.superKey
            onChosen: (k) => Config.options.cheatsheet.superKey = k
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Use macOS-like symbols for mods keys")
            checked: Config.options.cheatsheet.useMacSymbol
            onToggled: (v) => Config.options.cheatsheet.useMacSymbol = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Use symbols for function keys")
            checked: Config.options.cheatsheet.useFnSymbol
            onToggled: (v) => Config.options.cheatsheet.useFnSymbol = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Use symbols for mouse")
            checked: Config.options.cheatsheet.useMouseSymbol
            onToggled: (v) => Config.options.cheatsheet.useMouseSymbol = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Split buttons")
            checked: Config.options.cheatsheet.splitButtons
            onToggled: (v) => Config.options.cheatsheet.splitButtons = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Keybind font size")
            value: Config.options.cheatsheet.fontSize.key
            from: 8; to: 30; step: 1
            onModified: (v) => Config.options.cheatsheet.fontSize.key = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Description font size")
            value: Config.options.cheatsheet.fontSize.comment
            from: 8; to: 30; step: 1
            onModified: (v) => Config.options.cheatsheet.fontSize.comment = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("DOCK")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Enable")
            checked: Config.options.dock.enable
            onToggled: (v) => Config.options.dock.enable = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Hover to reveal")
            checked: Config.options.dock.hoverToReveal
            onToggled: (v) => Config.options.dock.hoverToReveal = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Pinned on startup")
            checked: Config.options.dock.pinnedOnStartup
            onToggled: (v) => Config.options.dock.pinnedOnStartup = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Tint app icons")
            checked: Config.options.dock.monochromeIcons
            onToggled: (v) => Config.options.dock.monochromeIcons = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("LOCK SCREEN")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Use Hyprlock (instead of Quickshell)")
            checked: Config.options.lockscreen.useHyprlock
            onToggled: (v) => Config.options.lockscreen.useHyprlock = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Background type")
            options: [
                { key: "0", label: Translation.tr("Wallpaper") },
                { key: "1", label: Translation.tr("Solid color") },
                { key: "2", label: Translation.tr("Blurred wallpaper") }
            ]
            current: String(Config.options.lockscreen.backgroundType)
            onChosen: (k) => Config.options.lockscreen.backgroundType = parseInt(k)
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Blur radius")
            value: Config.options.lockscreen.blurRadius
            from: 0; to: 50; step: 2
            visible: Config.options.lockscreen.backgroundType === 2
            onModified: (v) => Config.options.lockscreen.blurRadius = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Blur passes")
            value: Config.options.lockscreen.blurPasses
            from: 1; to: 10; step: 1
            visible: Config.options.lockscreen.backgroundType === 2
            onModified: (v) => Config.options.lockscreen.blurPasses = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Use greetd (instead of SDDM)")
            checked: Config.options.lockscreen.useGreetd
            onToggled: (v) => Config.options.lockscreen.useGreetd = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("NOTIFICATIONS")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Notification style")
            options: [
                { key: "0", label: Translation.tr("Minimal") },
                { key: "1", label: Translation.tr("Full") }
            ]
            current: String(Config.options.notifications.style)
            onChosen: (k) => Config.options.notifications.style = parseInt(k)
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show notification count")
            checked: Config.options.notifications.indicator.showCount
            onToggled: (v) => Config.options.notifications.indicator.showCount = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Popup duration (ms)")
            value: Config.options.notifications.popupDuration
            from: 1000; to: 30000; step: 500
            onModified: (v) => Config.options.notifications.popupDuration = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Max notifications shown")
            value: Config.options.notifications.maxNotifications
            from: 1; to: 20; step: 1
            onModified: (v) => Config.options.notifications.maxNotifications = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Max notifications per app")
            value: Config.options.notifications.maxNotificationsPerApp
            from: 1; to: 10; step: 1
            onModified: (v) => Config.options.notifications.maxNotificationsPerApp = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show progress bars")
            checked: Config.options.notifications.showProgress
            onToggled: (v) => Config.options.notifications.showProgress = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show images")
            checked: Config.options.notifications.showImage
            onToggled: (v) => Config.options.notifications.showImage = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("ANIMATIONS")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Animation speed")
            options: [
                { key: "0.5", label: Translation.tr("Slow") },
                { key: "1", label: Translation.tr("Normal") },
                { key: "1.5", label: Translation.tr("Fast") },
                { key: "2", label: Translation.tr("Very Fast") }
            ]
            current: String(Config.options.animation.multiplier)
            onChosen: (k) => Config.options.animation.multiplier = parseFloat(k)
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Reduced motion")
            checked: Config.options.animation.reducedMotion
            onToggled: (v) => Config.options.animation.reducedMotion = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("MOUSE & TOUCHPAD")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Natural scrolling")
            checked: Config.options.mouse.naturalScroll
            onToggled: (v) => Config.options.mouse.naturalScroll = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Pointer speed")
            value: Config.options.mouse.accelProfile === "flat" ? 1 : Math.round(Config.options.mouse.sensitivity * 10) / 10
            from: -1; to: 1; step: 0.1; decimals: 1
            onModified: (v) => {
                Config.options.mouse.sensitivity = Math.abs(v);
                Config.options.mouse.accelProfile = v >= 0 ? "adaptive" : "flat";
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("KEYBOARD")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Numlock on startup")
            checked: Config.options.keyboard.numlockOnStartup
            onToggled: (v) => Config.options.keyboard.numlockOnStartup = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Repeat rate (char/s)")
            value: Config.options.keyboard.repeatRate
            from: 15; to: 100; step: 5
            onModified: (v) => Config.options.keyboard.repeatRate = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Repeat delay (ms)")
            value: Config.options.keyboard.repeatDelay
            from: 100; to: 1000; step: 50
            onModified: (v) => Config.options.keyboard.repeatDelay = v
        }
    }
}
