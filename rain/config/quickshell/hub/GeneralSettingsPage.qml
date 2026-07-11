pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

Item {
    id: page

    property string currentLang: "auto"
    property string timeFormat: "hh:mm"

    function setConfig(k, v) {
        Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", k, String(v)]);
    }

    Process {
        id: langProc
        command: [Directories.rainBin, "hub", "config", "get", "language.ui"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var v = this.text.trim();
                page.currentLang = v.length > 0 ? v : "auto";
            }
        }
    }

    Process {
        id: timeProc
        command: [Directories.rainBin, "hub", "config", "get", "time.format"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var v = this.text.trim();
                page.timeFormat = v.length > 0 ? v : "hh:mm";
            }
        }
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
                width: parent.width; title: "AUDIO"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Earbang protection"
                    checked: false
                    onToggled: (v) => page.setConfig("audio.protection.enable", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Max increase"; unit: "%"
                    from: 0; to: 100; step: 2; value: 20
                    onModified: (v) => page.setConfig("audio.protection.maxAllowedIncrease", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Volume limit"; unit: "%"
                    from: 0; to: 154; step: 2; value: 100
                    onModified: (v) => page.setConfig("audio.protection.maxAllowed", v)
                }
            }

            SettingSection {
                width: parent.width; title: "BATTERY"

                NumberField {
                    width: Math.min(parent.width, 460); label: "Low warning"; unit: "%"
                    from: 0; to: 100; step: 5; value: 20
                    onModified: (v) => page.setConfig("battery.low", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Critical warning"; unit: "%"
                    from: 0; to: 100; step: 5; value: 5
                    onModified: (v) => page.setConfig("battery.critical", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Full warning"; unit: "%"
                    from: 0; to: 101; step: 5; value: 95
                    onModified: (v) => page.setConfig("battery.full", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Automatic suspend"
                    checked: false
                    onToggled: (v) => page.setConfig("battery.automaticSuspend", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Suspend at"; unit: "%"
                    from: 0; to: 100; step: 5; value: 3
                    onModified: (v) => page.setConfig("battery.suspend", v)
                }
            }

            SettingSection {
                width: parent.width; title: "LANGUAGE"

                Dropdown {
                    width: Math.min(parent.width, 460); label: "Interface language"
                    fieldWidth: 240
                    options: [
                        { key: "auto", label: "Auto (System)" },
                        { key: "en_US", label: "English" },
                        { key: "ja_JP", label: "Japanese" },
                        { key: "zh_CN", label: "Chinese (Simplified)" },
                        { key: "de_DE", label: "German" },
                        { key: "fr_FR", label: "French" }
                    ]
                    current: page.currentLang
                    onChosen: (k) => {
                        page.currentLang = k;
                        page.setConfig("language.ui", k);
                    }
                }
            }

            SettingSection {
                width: parent.width; title: "TIME"

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Format"
                    options: [
                        { key: "hh:mm", label: "24h" },
                        { key: "h:mm ap", label: "12h am/pm" },
                        { key: "h:mm AP", label: "12h AM/PM" }
                    ]
                    current: page.timeFormat
                    onChosen: (k) => {
                        page.timeFormat = k;
                        page.setConfig("time.format", k);
                    }
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Second precision"
                    checked: false
                    onToggled: (v) => page.setConfig("time.secondPrecision", v)
                }
            }

            SettingSection {
                width: parent.width; title: "POLICIES"

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "AI"
                    options: [
                        { key: "0", label: "No" },
                        { key: "1", label: "Yes" },
                        { key: "2", label: "Local only" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("policies.ai", k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Weeb"
                    options: [
                        { key: "0", label: "No" },
                        { key: "1", label: "Yes" },
                        { key: "2", label: "Closet" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("policies.weeb", k)
                }
            }

            SettingSection {
                width: parent.width; title: "SOUNDS"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Battery sounds"
                    checked: false
                    onToggled: (v) => page.setConfig("sounds.battery", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Pomodoro sounds"
                    checked: false
                    onToggled: (v) => page.setConfig("sounds.pomodoro", v)
                }
            }
        }
    }
}
