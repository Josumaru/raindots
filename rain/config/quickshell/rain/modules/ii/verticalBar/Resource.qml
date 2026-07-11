import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    implicitHeight: resourceProgress.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth

    property bool warning: percentage * 100 >= warningThreshold

    ClippedFilledCircularProgress {
        id: resourceProgress
        anchors.centerIn: parent
        value: percentage
        enableAnimation: false
        colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
        accountForLightBleeding: !root.warning

        Icon {
            name: root.iconName
            size: 13
            tint: Appearance.colors.colOnSecondaryContainer
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: root.visible
    }
}
