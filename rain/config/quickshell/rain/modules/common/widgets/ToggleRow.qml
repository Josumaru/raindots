import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: row
    property string label: ""
    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 320
    implicitHeight: 38

    opacity: row.enabled ? 1.0 : 0.45
    Behavior on opacity { NumberAnimation { duration: 120 } }

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
        width: 46
        height: 26
        radius: height / 2
        color: row.checked ? Appearance.warm.accent : Appearance.warm.bgSurfaceLow
        border.width: 1
        border.color: row.checked ? Appearance.warm.accent : (hov.hovered ? Appearance.warm.hairlineHover : Appearance.warm.hairline)
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Rectangle {
            id: knob
            width: 20
            height: 20
            radius: 10
            y: 3
            x: row.checked ? track.width - width - 3 : 3
            color: row.checked ? Appearance.warm.onAccent : Appearance.warm.onSurfaceDim
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutExpo } }
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: row.toggled(!row.checked) }
    }
}
