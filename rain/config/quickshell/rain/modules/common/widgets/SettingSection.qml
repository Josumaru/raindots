import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Column {
    id: sec
    property string title: ""
    default property alias items: body.data
    spacing: 14

    Item {
        width: sec.width
        height: 16

        StyledText {
            id: head
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: sec.title
            color: Appearance.warm.onSurfaceDim
            font.pixelSize: 11
            font.family: Appearance.font.family.mono
            font.weight: Font.DemiBold
            font.letterSpacing: 2
        }

        Rectangle {
            anchors.left: head.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: Appearance.warm.hairline
        }
    }

    Column {
        id: body
        width: sec.width
        spacing: 16
    }
}
