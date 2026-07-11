import QtQuick
import QtQuick.Layouts
import "Singletons"

// page header with eyebrow, title, subtitle, and config file buttons.
Item {
    id: header

    property string eyebrow: ""
    property string title: ""
    property string subtitle: ""
    property var configPaths: []

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 4

        RowLayout {
            spacing: 0

            Text {
                text: header.eyebrow.toUpperCase()
                color: Theme.ember
                font.family: Theme.mono
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 2
            }
            Text {
                text: " · LIVE"
                visible: header.eyebrow === "Desktop"
                color: Theme.faint
                font.family: Theme.mono
                font.pixelSize: 11
                font.letterSpacing: 2
                Layout.leftMargin: 8
            }
        }

        Text {
            text: header.title
            color: Theme.bright
            font.family: Theme.display
            font.pixelSize: 28
            font.weight: Font.Medium
        }

        RowLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: header.subtitle
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: header.configPaths
                delegate: Rectangle {
                    id: cfgBtn
                    required property string modelData
                    implicitHeight: 28
                    implicitWidth: cfgLabel.width + 22
                    radius: 0
                    color: cfgHover.hovered ? Theme.surface : "transparent"
                    border.width: 1
                    border.color: cfgHover.hovered ? Theme.line : Theme.lineSoft
                    Behavior on color { ColorAnimation { duration: Theme.quick } }
                    Behavior on border.color { ColorAnimation { duration: Theme.quick } }

                    Text {
                        id: cfgLabel
                        anchors.centerIn: parent
                        text: {
                            var parts = cfgBtn.modelData.split("/");
                            return parts[parts.length - 1];
                        }
                        color: Theme.dim
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }
                    HoverHandler { id: cfgHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Qt.openUrlExternally("file://" + cfgBtn.modelData) }
                }
            }
        }
    }
}
