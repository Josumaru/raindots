pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: row
    property string label: ""
    property var options: []
    property string current: ""
    signal chosen(string key)

    implicitWidth: 320
    implicitHeight: 38

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - track.width - 14
        elide: Text.ElideRight
        text: row.label
        color: Appearance.warm.onSurface
        font.pixelSize: 14
        font.weight: Font.Medium
    }

    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        width: seg.width + 6
        color: Appearance.warm.bgSurfaceLow
        border.width: 1
        border.color: Appearance.warm.hairline

        Row {
            id: seg
            anchors.centerIn: parent
            spacing: 0

            Repeater {
                model: row.options

                delegate: Rectangle {
                    id: cell
                    required property var modelData
                    readonly property bool active: row.current === cell.modelData.key
                    width: cellText.implicitWidth + 26
                    height: 26
                    color: cell.active ? Appearance.warm.bgSurfaceHigh : "transparent"
                    border.width: cell.active ? 1 : 0
                    border.color: cell.active ? Appearance.warm.hairline : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    StyledText {
                        id: cellText
                        anchors.centerIn: parent
                        text: cell.modelData.label
                        color: cell.active ? Appearance.warm.onSurface : (cellHov.hovered ? Appearance.warm.onSurface : Appearance.warm.onSurfaceDim)
                        font.pixelSize: 12
                        font.weight: cell.active ? Font.DemiBold : Font.Medium
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    HoverHandler { id: cellHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: row.chosen(cell.modelData.key) }
                }
            }
        }
    }
}
