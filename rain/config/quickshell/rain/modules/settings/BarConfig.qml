import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    SettingSection {
        width: parent.width
        title: Translation.tr("NOTIFICATIONS")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onToggled: (v) => Config.options.bar.indicators.notifications.showUnreadCount = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("POSITIONING")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Bar position")
            options: [
                { key: "0", label: Translation.tr("Top") },
                { key: "2", label: Translation.tr("Left") },
                { key: "1", label: Translation.tr("Bottom") },
                { key: "3", label: Translation.tr("Right") }
            ]
            current: String((Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0))
            onChosen: (k) => {
                var v = parseInt(k);
                Config.options.bar.bottom = (v & 1) !== 0;
                Config.options.bar.vertical = (v & 2) !== 0;
            }
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Auto hide")
            options: [
                { key: "false", label: Translation.tr("No") },
                { key: "true", label: Translation.tr("Yes") }
            ]
            current: String(Config.options.bar.autoHide.enable)
            onChosen: (k) => Config.options.bar.autoHide.enable = k === "true"
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Corner style")
            options: [
                { key: "0", label: Translation.tr("Hug") },
                { key: "1", label: Translation.tr("Float") },
                { key: "2", label: Translation.tr("Rect") }
            ]
            current: String(Config.options.bar.cornerStyle)
            onChosen: (k) => Config.options.bar.cornerStyle = parseInt(k)
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Group style")
            options: [
                { key: "false", label: Translation.tr("Pills") },
                { key: "true", label: Translation.tr("Line-separated") }
            ]
            current: String(Config.options.bar.borderless)
            onChosen: (k) => Config.options.bar.borderless = k === "true"
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("TRAY")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Make icons pinned by default")
            checked: Config.options.bar.indicators.tray.pinnedByDefault
            onToggled: (v) => Config.options.bar.indicators.tray.pinnedByDefault = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Icon size")
            options: [
                { key: "16", label: "16" },
                { key: "20", label: "20" },
                { key: "24", label: "24" },
                { key: "28", label: "28" },
                { key: "32", label: "32" }
            ]
            current: String(Config.options.bar.indicators.tray.iconSize)
            onChosen: (k) => Config.options.bar.indicators.tray.iconSize = parseInt(k)
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Spacing")
            options: [
                { key: "0", label: Translation.tr("None") },
                { key: "4", label: "4" },
                { key: "8", label: "8" },
                { key: "12", label: "12" },
                { key: "16", label: "16" }
            ]
            current: String(Config.options.bar.indicators.tray.spacing)
            onChosen: (k) => Config.options.bar.indicators.tray.spacing = parseInt(k)
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("WORKSPACES")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Indicator")
            options: [
                { key: "0", label: Translation.tr("Numbers") },
                { key: "1", label: Translation.tr("Dots") }
            ]
            current: String(Config.options.bar.indicators.workspaces.useDots ? 1 : 0)
            onChosen: (k) => Config.options.bar.indicators.workspaces.useDots = parseInt(k) === 1
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show workspace names")
            checked: Config.options.bar.indicators.workspaces.showName
            onToggled: (v) => Config.options.bar.indicators.workspaces.showName = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Number style")
            options: [
                { key: "0", label: Translation.tr("Regular") },
                { key: "1", label: Translation.tr("Super/subscript") }
            ]
            current: String(Config.options.bar.indicators.workspaces.numeralType)
            onChosen: (k) => Config.options.bar.indicators.workspaces.numeralType = parseInt(k)
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("CLOCK")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show date")
            checked: Config.options.bar.indicators.clock.showDate
            onToggled: (v) => Config.options.bar.indicators.clock.showDate = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Date style")
            options: [
                { key: "0", label: Translation.tr("Short") },
                { key: "1", label: Translation.tr("Long") }
            ]
            current: String(Config.options.bar.indicators.clock.dateStyle)
            onChosen: (k) => Config.options.bar.indicators.clock.dateStyle = parseInt(k)
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("LAUNCHER")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show launcher button")
            checked: Config.options.bar.indicators.launcher.showLauncherButton
            onToggled: (v) => Config.options.bar.indicators.launcher.showLauncherButton = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Icon")
            options: [
                { key: "0", label: Translation.tr("Default") },
                { key: "1", label: Translation.tr("Logo") }
            ]
            current: String(Config.options.bar.indicators.launcher.launcherIcon)
            onChosen: (k) => Config.options.bar.indicators.launcher.launcherIcon = parseInt(k)
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("MEDIA")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show media controls")
            checked: Config.options.bar.indicators.media.enableMediaControls
            onToggled: (v) => Config.options.bar.indicators.media.enableMediaControls = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Media display mode")
            options: [
                { key: "0", label: Translation.tr("Compact") },
                { key: "1", label: Translation.tr("Full") }
            ]
            current: String(Config.options.bar.indicators.media.mode)
            onChosen: (k) => Config.options.bar.indicators.media.mode = parseInt(k)
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("SIDEBAR")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show sidebar buttons")
            checked: Config.options.bar.indicators.sidebar.enable
            onToggled: (v) => Config.options.bar.indicators.sidebar.enable = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("SYSTEM TRAY")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Enable tray")
            checked: Config.options.bar.indicators.tray.enable
            onToggled: (v) => Config.options.bar.indicators.tray.enable = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Highlight new items")
            checked: Config.options.bar.indicators.tray.highlightNew
            onToggled: (v) => Config.options.bar.indicators.tray.highlightNew = v
        }
    }
}
