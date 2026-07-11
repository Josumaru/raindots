import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "Singletons"

// display detection and basic info.
Item {
    id: page

    property var monitors: []

    Process {
        id: monitorProc
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.monitors = JSON.parse(this.text); } catch (e) {}
            }
        }
        running: true
    }

    Component.onCompleted: monitorProc.running = true

    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 30

        SettingSection {
            width: parent.width
            title: "MONITORS"

            ColumnLayout {
                width: parent.width
                spacing: 12

                Repeater {
                    model: page.monitors
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        implicitHeight: 64
                        color: Theme.surfaceLo
                        border.width: 1
                        border.color: Theme.line

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 4

                            Text {
                                text: modelData.name || "unknown"
                                color: Theme.bright
                                font.family: Theme.font
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: (modelData.width || 0) + "x" + (modelData.height || 0)
                                    + " @" + (modelData.refreshRate || 0).toFixed(1) + "Hz"
                                    + " · scale " + (modelData.scale || 1).toFixed(1)
                                    + (modelData.focused ? " · focused" : "")
                                color: Theme.dim
                                font.family: Theme.mono
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Text {
                    visible: page.monitors.length === 0
                    text: "Detecting monitors..."
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Use nwg-displays or Hyprland config for persistent monitor layout."
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 12
                    Layout.topMargin: 8
                }
            }
        }
    }
}
