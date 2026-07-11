pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

Item {
    id: page

    property string distroName: ""
    property string distroLogo: ""
    property string homeUrl: ""
    property string docsUrl: ""
    property string supportUrl: ""
    property string bugsUrl: ""
    property string privacyUrl: ""
    property string shellVersion: ""

    Process {
        id: infoProc
        command: [Directories.rainBin, "hub", "config", "get", "system.distroName"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                page.distroName = this.text.trim();
            }
        }
    }
    Process {
        id: verProc
        command: [Directories.rainBin, "hub", "config", "get", "system.shellVersion"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                page.shellVersion = this.text.trim();
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
                width: parent.width; title: "DISTRO"

                Row {
                    width: parent.width; spacing: 20

                    Rectangle {
                        width: 80; height: 80
                        color: Theme.surfaceLo
                        border.width: 1; border.color: Theme.line

                        Icon {
                            anchors.centerIn: parent
                            name: "star"; size: 36
                            tint: Theme.dim
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: page.distroName.length > 0 ? page.distroName : "Loading..."
                            color: Theme.bright
                            font.family: Theme.display
                            font.pixelSize: 22
                            font.weight: Font.Medium
                        }

                        Text {
                            text: "Raindots Linux"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 13
                        }
                    }
                }

                Row {
                    width: parent.width; spacing: 10

                    HubButton {
                        label: "Documentation"; icon: "folder"
                        onClicked: Qt.openUrlExternally("https://github.com/illogical-impulse/raindots")
                    }

                    HubButton {
                        label: "Help & Support"; icon: "users"
                        onClicked: Qt.openUrlExternally("https://github.com/illogical-impulse/raindots/issues")
                    }

                    HubButton {
                        label: "Report a Bug"; icon: "wrench"
                        onClicked: Qt.openUrlExternally("https://github.com/illogical-impulse/raindots/issues/new")
                    }

                    HubButton {
                        label: "Privacy"; icon: "lock"
                        onClicked: Qt.openUrlExternally("https://github.com/illogical-impulse/raindots")
                    }
                }
            }

            SettingSection {
                width: parent.width; title: "DOTFILES"

                Row {
                    width: parent.width; spacing: 20

                    Rectangle {
                        width: 80; height: 80
                        color: Theme.surfaceLo
                        border.width: 1; border.color: Theme.line

                        Icon {
                            anchors.centerIn: parent
                            name: "heart"; size: 36
                            tint: Theme.ember
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: "Raindots"
                            color: Theme.bright
                            font.family: Theme.display
                            font.pixelSize: 22
                            font.weight: Font.Medium
                        }

                        Text {
                            text: "illogical-impulse/raindots"
                            color: Theme.ember
                            font.family: Theme.mono
                            font.pixelSize: 12
                        }
                    }
                }

                Row {
                    width: parent.width; spacing: 10

                    HubButton {
                        label: "Star on GitHub"; icon: "star"; primary: true
                        onClicked: Qt.openUrlExternally("https://github.com/illogical-impulse/raindots")
                    }

                    HubButton {
                        label: "Fork the project"; icon: "compass"
                        onClicked: Qt.openUrlExternally("https://github.com/illogical-impulse/raindots/fork")
                    }
                }
            }

            SettingSection {
                width: parent.width; title: "TECHNICAL"

                Row {
                    width: parent.width; spacing: 16

                    Column {
                        width: (parent.width - 16) / 2
                        spacing: 4

                        Text {
                            text: "Version"
                            color: Theme.dim
                            font.family: Theme.mono
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.5
                        }

                        Text {
                            text: page.shellVersion.length > 0 ? page.shellVersion : "—"
                            color: Theme.bright
                            font.family: Theme.font
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        width: (parent.width - 16) / 2
                        spacing: 4

                        Text {
                            text: "Shell"
                            color: Theme.dim
                            font.family: Theme.mono
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.5
                        }

                        Text {
                            text: "Rain II"
                            color: Theme.bright
                            font.family: Theme.font
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }
}
