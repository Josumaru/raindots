pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

Item {
    id: page

    property string group: "wallpaper"
    property string currentLang: ""
    property string currentPalette: ""
    property string currentScheme: "follow"

    function applyLang(k) {
        page.currentLang = k;
        Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", "language.ui", k]);
    }
    function applyScheme(k) {
        page.currentScheme = k;
        Quickshell.execDetached([Directories.rainBin, "hub", "hypr", "scheme", k]);
    }
    function applyPalette(k) {
        page.currentPalette = k;
        Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", "palette.type", k]);
    }
    function applyWallpaper() {
        Quickshell.execDetached([Directories.rainBin, "wallpaperpicker"]);
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
        id: schemeProc
        command: [Directories.rainBin, "hub", "hypr", "scheme"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text);
                    page.currentScheme = d.scheme || "follow";
                } catch (e) {}
            }
        }
    }

    Process {
        id: paletteProc
        command: [Directories.rainBin, "hub", "config", "get", "palette.type"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var v = this.text.trim();
                page.currentPalette = v.length > 0 ? v : "auto";
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
                width: parent.width; title: "INTERFACE LANGUAGE"

                Dropdown {
                    width: Math.min(parent.width, 460); label: "Language"
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
                    onChosen: (k) => page.applyLang(k)
                }
            }

            SettingSection {
                width: parent.width; title: "WALLPAPER & COLORS"

                Row {
                    width: parent.width; spacing: 12

                    Rectangle {
                        width: 120; height: 76
                        color: Theme.surfaceLo
                        border.width: 1; border.color: Theme.line

                        Icon {
                            anchors.centerIn: parent
                            name: "wallpaper"; size: 28
                            tint: Theme.dim
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        HubButton {
                            label: "Pick wallpaper"; icon: "image"
                            onClicked: page.applyWallpaper()
                        }
                    }
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Mode"
                    options: [
                        { key: "follow", label: "Follow wallpaper" },
                        { key: "light", label: "Light" },
                        { key: "dark", label: "Dark" }
                    ]
                    current: page.currentScheme
                    onChosen: (k) => page.applyScheme(k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Palette"
                    options: [
                        { key: "auto", label: "Auto" },
                        { key: "scheme-content", label: "Content" },
                        { key: "scheme-expressive", label: "Expressive" },
                        { key: "scheme-fidelity", label: "Fidelity" },
                        { key: "scheme-monochrome", label: "Monochrome" },
                        { key: "scheme-neutral", label: "Neutral" },
                        { key: "scheme-tonal-spot", label: "Tonal Spot" }
                    ]
                    current: page.currentPalette
                    onChosen: (k) => page.applyPalette(k)
                }
            }

            SettingSection {
                width: parent.width; title: "BAR & SCREEN"

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Bar position"
                    options: [
                        { key: "top", label: "Top" },
                        { key: "bottom", label: "Bottom" },
                        { key: "left", label: "Left" },
                        { key: "right", label: "Right" }
                    ]
                    current: "top"
                    onChosen: (k) => Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", "bar.position", k])
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Bar style"
                    options: [
                        { key: "0", label: "Hug" },
                        { key: "1", label: "Float" },
                        { key: "2", label: "Rect" }
                    ]
                    current: "0"
                    onChosen: (k) => Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", "bar.cornerStyle", k])
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Screen rounding"
                    options: [
                        { key: "0", label: "No" },
                        { key: "1", label: "Yes" },
                        { key: "2", label: "When not fullscreen" }
                    ]
                    current: "0"
                    onChosen: (k) => Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", "appearance.fakeScreenRounding", k])
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Transparency"
                    checked: false
                    onToggled: (v) => Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", "appearance.transparency.enable", String(v)])
                }
            }
        }
    }
}
