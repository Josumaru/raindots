import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root
    Layout.alignment: Qt.AlignLeft
    implicitWidth: 40
    implicitHeight: 40
    Layout.leftMargin: 8
    downAction: () => {
        parent.expanded = !parent.expanded;
    }
    buttonRadius: Appearance.rounding.full

    rotation: root.parent.expanded ? 0 : -180
    Behavior on rotation {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    contentItem: Icon {
        id: icon
        size: 24
        tint: Appearance.colors.colOnLayer1
        name: root.parent.expanded ? "chevron" : "chevron"
    }
}
