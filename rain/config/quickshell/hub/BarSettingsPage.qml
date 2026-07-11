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
                width: parent.width; title: "NOTIFICATIONS"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show unread count"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.notifications.showUnreadCount", v)
                }
            }

            SettingSection {
                width: parent.width; title: "POSITIONING"

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Bar position"
                    options: [
                        { key: "top", label: "Top" },
                        { key: "bottom", label: "Bottom" },
                        { key: "left", label: "Left" },
                        { key: "right", label: "Right" }
                    ]
                    current: "top"
                    onChosen: (k) => page.setConfig("bar.position", k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Auto hide"
                    options: [
                        { key: "false", label: "No" },
                        { key: "true", label: "Yes" }
                    ]
                    current: "false"
                    onChosen: (k) => page.setConfig("bar.autoHide.enable", k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Corner style"
                    options: [
                        { key: "0", label: "Hug" },
                        { key: "1", label: "Float" },
                        { key: "2", label: "Rect" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("bar.cornerStyle", k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Group style"
                    options: [
                        { key: "false", label: "Pills" },
                        { key: "true", label: "Line-separated" }
                    ]
                    current: "false"
                    onChosen: (k) => page.setConfig("bar.borderless", k)
                }
            }

            SettingSection {
                width: parent.width; title: "TRAY"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Pinned by default"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.tray.pinnedByDefault", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Icon size"
                    options: [
                        { key: "16", label: "16" },
                        { key: "20", label: "20" },
                        { key: "24", label: "24" },
                        { key: "28", label: "28" },
                        { key: "32", label: "32" }
                    ]
                    current: "24"
                    onChosen: (k) => page.setConfig("bar.indicators.tray.iconSize", k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Spacing"
                    options: [
                        { key: "0", label: "None" },
                        { key: "4", label: "4" },
                        { key: "8", label: "8" },
                        { key: "12", label: "12" },
                        { key: "16", label: "16" }
                    ]
                    current: "8"
                    onChosen: (k) => page.setConfig("bar.indicators.tray.spacing", k)
                }
            }

            SettingSection {
                width: parent.width; title: "WORKSPACES"

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Indicator"
                    options: [
                        { key: "0", label: "Numbers" },
                        { key: "1", label: "Dots" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("bar.indicators.workspaces.useDots", k)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show workspace names"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.workspaces.showName", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Number style"
                    options: [
                        { key: "0", label: "Regular" },
                        { key: "1", label: "Super/subscript" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("bar.indicators.workspaces.numeralType", k)
                }
            }

            SettingSection {
                width: parent.width; title: "CLOCK"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show date"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.clock.showDate", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Date style"
                    options: [
                        { key: "0", label: "Short" },
                        { key: "1", label: "Long" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("bar.indicators.clock.dateStyle", k)
                }
            }

            SettingSection {
                width: parent.width; title: "LAUNCHER"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show launcher button"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.launcher.showLauncherButton", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Icon"
                    options: [
                        { key: "0", label: "Default" },
                        { key: "1", label: "Logo" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("bar.indicators.launcher.launcherIcon", k)
                }
            }

            SettingSection {
                width: parent.width; title: "MEDIA"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show media controls"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.media.enableMediaControls", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Display mode"
                    options: [
                        { key: "0", label: "Compact" },
                        { key: "1", label: "Full" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("bar.indicators.media.mode", k)
                }
            }

            SettingSection {
                width: parent.width; title: "SIDEBAR"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show sidebar buttons"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.sidebar.enable", v)
                }
            }

            SettingSection {
                width: parent.width; title: "SYSTEM TRAY"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable tray"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.tray.enable", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Highlight new items"
                    checked: false
                    onToggled: (v) => page.setConfig("bar.indicators.tray.highlightNew", v)
                }
            }
        }
    }
}
