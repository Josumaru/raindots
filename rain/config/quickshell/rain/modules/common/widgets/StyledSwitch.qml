import qs.modules.common
import QtQuick
import QtQuick.Controls

Switch {
    id: root
    property real scale: 0.75
    implicitHeight: 32 * root.scale
    implicitWidth: 52 * root.scale
    property color activeColor: Appearance?.colors.colPrimary ?? "#685496"
    property color inactiveColor: Appearance?.colors.colSurfaceContainerHighest ?? "#45464F"

    PointingHandInteraction {}

    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: height / 2
        color: root.checked ? root.activeColor : root.inactiveColor
        border.width: 1
        border.color: root.checked ? root.activeColor : Appearance.m3colors.m3outline

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    indicator: Rectangle {
        width: (root.pressed || root.down) ? (28 * root.scale) : (22 * root.scale)
        height: (root.pressed || root.down) ? (28 * root.scale) : (22 * root.scale)
        radius: width / 2
        color: root.checked ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3outline
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.checked ?
            parent.width - width - (root.pressed ? 2 * root.scale : 3 * root.scale) :
            (root.pressed ? 2 * root.scale : 3 * root.scale)

        Behavior on anchors.leftMargin {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutExpo
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutExpo
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutExpo
            }
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
