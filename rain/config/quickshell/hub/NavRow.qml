import QtQuick
import "Singletons"

Item {
    id: navRow
    required property var modelData
    property string currentSection: ""
    property var navigate: null

    readonly property string key: modelData.key
    readonly property string name: modelData.name
    readonly property string icon: modelData.icon || ""
    readonly property bool selected: key === currentSection

    width: parent ? parent.width : 252
    height: 34

    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 0
        anchors.right: parent.right; anchors.rightMargin: 0
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        radius: Theme.radius
        color: selected ? Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, 0.12) : (navHover.hovered ? Theme.surfaceLo : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.quick } }

        Icon {
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            name: icon; size: 16
            tint: selected ? Theme.ember : Theme.dim
        }

        Text {
            anchors.left: parent.left; anchors.leftMargin: 36
            anchors.verticalCenter: parent.verticalCenter
            text: name
            color: selected ? Theme.bright : Theme.subtle
            font.family: Theme.font; font.pixelSize: 13
            font.weight: selected ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: navHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (navRow.navigate) navRow.navigate(key); }
    }
}
