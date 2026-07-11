import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Row {
    id: root
    required property var icon
    required property var label
    spacing: 5

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: Appearance.font.pixelSize.large
        tint: Appearance.colors.colOnSurfaceVariant
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font {
            weight: Font.DemiBold
            pixelSize: Appearance.font.pixelSize.normal
        }
        color: Appearance.colors.colOnSurfaceVariant
    }
}