import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    SettingSection {
        width: parent.width
        title: Translation.tr("PARALLAX")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Vertical")
            checked: Config.options.background.parallax.vertical
            onToggled: (v) => Config.options.background.parallax.vertical = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Depends on workspace")
            checked: Config.options.background.parallax.enableWorkspace
            onToggled: (v) => Config.options.background.parallax.enableWorkspace = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Depends on sidebars")
            checked: Config.options.background.parallax.enableSidebar
            onToggled: (v) => Config.options.background.parallax.enableSidebar = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Preferred wallpaper zoom (%)")
            value: Config.options.background.parallax.workspaceZoom * 100
            from: 10; to: 200; step: 1
            onModified: (v) => Config.options.background.parallax.workspaceZoom = v / 100
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("WIDGET: CLOCK")

        function stylePresent(styleName) {
            if (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === styleName) return true;
            if (Config.options.background.widgets.clock.styleLocked === styleName) return true;
            return false;
        }

        readonly property bool digitalPresent: stylePresent("digital")
        readonly property bool cookiePresent: stylePresent("cookie")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Enable")
            checked: Config.options.background.widgets.clock.enable
            onToggled: (v) => Config.options.background.widgets.clock.enable = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Placement")
            options: [
                { key: "free", label: Translation.tr("Draggable") },
                { key: "leastBusy", label: Translation.tr("Least busy") },
                { key: "mostBusy", label: Translation.tr("Most busy") }
            ]
            current: Config.options.background.widgets.clock.placementStrategy
            onChosen: (k) => Config.options.background.widgets.clock.placementStrategy = k
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show only when locked")
            checked: Config.options.background.widgets.clock.showOnlyWhenLocked
            onToggled: (v) => Config.options.background.widgets.clock.showOnlyWhenLocked = v
        }

        ChoiceRow {
            width: parent.width
            visible: !Config.options.background.widgets.clock.showOnlyWhenLocked
            label: Translation.tr("Clock style")
            options: [
                { key: "digital", label: Translation.tr("Digital") },
                { key: "cookie", label: Translation.tr("Cookie") }
            ]
            current: Config.options.background.widgets.clock.style
            onChosen: (k) => Config.options.background.widgets.clock.style = k
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Clock style (locked)")
            options: [
                { key: "digital", label: Translation.tr("Digital") },
                { key: "cookie", label: Translation.tr("Cookie") }
            ]
            current: Config.options.background.widgets.clock.styleLocked
            onChosen: (k) => Config.options.background.widgets.clock.styleLocked = k
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Show tick marks")
            checked: Config.options.background.widgets.clock.showTicks
            onToggled: (v) => Config.options.background.widgets.clock.showTicks = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Force analog")
            checked: Config.options.background.widgets.clock.forceAnalog
            onToggled: (v) => Config.options.background.widgets.clock.forceAnalog = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Padding")
            value: Config.options.background.widgets.clock.padding
            from: 0; to: 100; step: 2
            onModified: (v) => Config.options.background.widgets.clock.padding = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Face style")
            options: [
                { key: "mono", label: Translation.tr("Monochrome") },
                { key: "accent", label: Translation.tr("Accent") }
            ]
            current: Config.options.background.widgets.clock.faceStyle
            onChosen: (k) => Config.options.background.widgets.clock.faceStyle = k
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("WIDGET: WEATHER")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Enable")
            checked: Config.options.background.widgets.weather.enable
            onToggled: (v) => Config.options.background.widgets.weather.enable = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Update interval (min)")
            value: Config.options.background.widgets.weather.updateInterval
            from: 5; to: 120; step: 5
            onModified: (v) => Config.options.background.widgets.weather.updateInterval = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Placement")
            options: [
                { key: "free", label: Translation.tr("Draggable") },
                { key: "leastBusy", label: Translation.tr("Least busy") },
                { key: "mostBusy", label: Translation.tr("Most busy") }
            ]
            current: Config.options.background.widgets.weather.placementStrategy
            onChosen: (k) => Config.options.background.widgets.weather.placementStrategy = k
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("WIDGET: NOTES")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Enable")
            checked: Config.options.background.widgets.notes.enable
            onToggled: (v) => Config.options.background.widgets.notes.enable = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Placement")
            options: [
                { key: "free", label: Translation.tr("Draggable") },
                { key: "leastBusy", label: Translation.tr("Least busy") },
                { key: "mostBusy", label: Translation.tr("Most busy") }
            ]
            current: Config.options.background.widgets.notes.placementStrategy
            onChosen: (k) => Config.options.background.widgets.notes.placementStrategy = k
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("WIDGET: DEVICES")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Enable")
            checked: Config.options.background.widgets.devices.enable
            onToggled: (v) => Config.options.background.widgets.devices.enable = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Placement")
            options: [
                { key: "free", label: Translation.tr("Draggable") },
                { key: "leastBusy", label: Translation.tr("Least busy") },
                { key: "mostBusy", label: Translation.tr("Most busy") }
            ]
            current: Config.options.background.widgets.devices.placementStrategy
            onChosen: (k) => Config.options.background.widgets.devices.placementStrategy = k
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("FONTS")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Clock font variant")
            options: [
                { key: "default", label: Translation.tr("Default") },
                { key: "numbers", label: Translation.tr("Numbers") },
                { key: "title", label: Translation.tr("Title") }
            ]
            current: Config.options.background.widgets.clock.clockFont || "default"
            onChosen: (k) => Config.options.background.widgets.clock.clockFont = k === "default" ? "" : k
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Use custom clock font size")
            checked: Config.options.background.widgets.clock.clockFontSize > 0
            onToggled: (v) => Config.options.background.widgets.clock.clockFontSize = v ? 48 : 0
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Custom clock font size")
            value: Config.options.background.widgets.clock.clockFontSize || 48
            from: 12; to: 200; step: 4
            visible: Config.options.background.widgets.clock.clockFontSize > 0
            onModified: (v) => Config.options.background.widgets.clock.clockFontSize = v
        }
    }
}
