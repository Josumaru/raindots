import qs.modules.common
import qs.modules.common.widgets
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    toggled: false
    buttonRadius: (altAction && toggled) ? Appearance?.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    buttonRadiusPressed: Appearance?.rounding?.small

    contentItem: Icon {
        anchors.centerIn: parent
        size: 22
        tint: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        name: buttonIcon

        Behavior on tint {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
