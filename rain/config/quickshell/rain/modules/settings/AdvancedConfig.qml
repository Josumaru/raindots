import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    SettingSection {
        width: parent.width
        title: Translation.tr("COLOR GENERATION")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Shell & utilities")
            checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onToggled: (v) => Config.options.appearance.wallpaperTheming.enableAppsAndShell = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Qt apps")
            checked: Config.options.appearance.wallpaperTheming.enableQtApps
            onToggled: (v) => Config.options.appearance.wallpaperTheming.enableQtApps = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Terminal")
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onToggled: (v) => Config.options.appearance.wallpaperTheming.enableTerminal = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Force dark mode in terminal")
            checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
            onToggled: (v) => Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Terminal: Harmony (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
            from: 0; to: 100; step: 10
            onModified: (v) => Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = v / 100
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Terminal: Harmonize threshold")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
            from: 0; to: 100; step: 10
            onModified: (v) => Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Terminal: Foreground boost (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
            from: 0; to: 100; step: 10
            onModified: (v) => Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = v / 100
        }
    }
}
