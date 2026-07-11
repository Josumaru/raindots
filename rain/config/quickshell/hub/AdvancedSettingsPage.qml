pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

Item {
    id: page

    function setConfig(k, v) {
        Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", k, String(v)]);
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.bottomMargin: 18
        contentWidth: width
        contentHeight: Math.max(col.height, height)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: sb; policy: ScrollBar.AsNeeded; width: 7
            contentItem: Rectangle {
                implicitWidth: 4; radius: Theme.radius; color: Theme.line
                opacity: sb.pressed ? 0.9 : (sb.hovered ? 0.7 : 0.4)
                Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            }
        }

        Column {
            id: col
            width: flick.width - 12
            spacing: 30

            SettingSection {
                width: parent.width; title: "COLOR GENERATION"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Shell & utilities theming"
                    checked: false
                    onToggled: (v) => page.setConfig("appearance.wallpaperTheming.enableAppsAndShell", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Qt apps theming"
                    checked: false
                    onToggled: (v) => page.setConfig("appearance.wallpaperTheming.enableQtApps", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Terminal theming"
                    checked: false
                    onToggled: (v) => page.setConfig("appearance.wallpaperTheming.enableTerminal", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Force dark mode in terminal"
                    checked: false
                    onToggled: (v) => page.setConfig("appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode", v)
                }

                SliderRow {
                    width: Math.min(parent.width, 460); label: "Terminal harmony"; percent: true
                    from: 0; to: 1; step: 0.1; decimals: 1; value: 0.5
                    onModified: (v) => page.setConfig("appearance.wallpaperTheming.terminalGenerationProps.harmony", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Harmonize threshold"; unit: "%"
                    from: 0; to: 100; step: 10; value: 50
                    onModified: (v) => page.setConfig("appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold", v)
                }

                SliderRow {
                    width: Math.min(parent.width, 460); label: "Foreground boost"; percent: true
                    from: 0; to: 1; step: 0.1; decimals: 1; value: 0.3
                    onModified: (v) => page.setConfig("appearance.wallpaperTheming.terminalGenerationProps.termFgBoost", v)
                }
            }

            SettingSection {
                width: parent.width; title: "WORK SAFETY"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Hide clipboard images from sussy sources"
                    checked: false
                    onToggled: (v) => page.setConfig("workSafety.enable.clipboard", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Hide sussy/anime wallpapers"
                    checked: false
                    onToggled: (v) => page.setConfig("workSafety.enable.wallpaper", v)
                }
            }
        }
    }
}
