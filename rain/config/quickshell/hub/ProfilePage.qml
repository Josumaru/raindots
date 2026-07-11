import QtQuick
import QtQuick.Layouts
import "Singletons"

// system profile card: hostname, OS, kernel, CPU, GPU, RAM.
Column {
    id: page

    spacing: 30

    SettingSection {
        width: parent.width
        title: "MACHINE"

        ColumnLayout {
            width: parent.width
            spacing: 12

            Repeater {
                model: [
                    { "label": "Hostname", "value": SysInfo.hostname },
                    { "label": "OS",       "value": SysInfo.os },
                    { "label": "Kernel",   "value": SysInfo.kernel },
                    { "label": "CPU",      "value": SysInfo.cpu },
                    { "label": "GPU",      "value": SysInfo.gpu }
                ]

                delegate: RowLayout {
                    required property var modelData
                    width: parent.width
                    spacing: 16

                    Text {
                        text: modelData.label
                        color: Theme.dim
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                        Layout.preferredWidth: 80
                    }
                    Text {
                        text: modelData.value || "detecting..."
                        color: Theme.bright
                        font.family: Theme.font
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            // RAM bar
            RowLayout {
                width: parent.width
                spacing: 16

                Text {
                    text: "RAM"
                    color: Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    Layout.preferredWidth: 80
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 0
                    color: Theme.surfaceLo
                    border.width: 1
                    border.color: Theme.line

                    Rectangle {
                        width: parent.width * SysInfo.ramPct
                        height: parent.height
                        color: SysInfo.ramPct > 0.8 ? Theme.ember : Theme.ember
                        opacity: 0.6
                    }
                }

                Text {
                    text: Math.round(SysInfo.ramUsed) + " MB / " + Math.round(SysInfo.ramTotal) + " MB"
                    color: Theme.subtle
                    font.family: Theme.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
