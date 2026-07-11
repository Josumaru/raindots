import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    radius: Appearance.rounding.small
    color: Appearance.colors.colSurfaceContainerHigh
    implicitWidth: columnLayout.implicitWidth + 14 * 2
    implicitHeight: columnLayout.implicitHeight + 14 * 2
    Layout.fillWidth: parent

    property alias title: title.text
    property alias value: value.text
    property alias symbol: symbol.name

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: -10
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Icon {
                id: symbol
                size: Appearance.font.pixelSize.normal
                tint: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                id: title
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
        StyledText {
            id: value
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
}
