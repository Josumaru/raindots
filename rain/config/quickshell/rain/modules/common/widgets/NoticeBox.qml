import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property alias materialIcon: icon.name
    property alias text: noticeText.text
    default property alias boxData: buttonRow.data

    radius: Appearance.rounding.normal
    color: Appearance.colors.colPrimaryContainer
    implicitWidth: mainRowLayout.implicitWidth + mainRowLayout.anchors.margins * 2
    implicitHeight: mainRowLayout.implicitHeight + mainRowLayout.anchors.margins * 2

    RowLayout {
        id: mainRowLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Icon {
            id: icon
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            name: "info"
            size: Appearance.font.pixelSize.huge
            tint: Appearance.colors.colOnPrimaryContainer
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            StyledText {
                id: noticeText
                Layout.fillWidth: true
                text: "Notice message"
                color: Appearance.colors.colOnPrimaryContainer
                wrapMode: Text.WordWrap
            }

            RowLayout {
                id: buttonRow
                visible: children.length > 0
                Layout.fillWidth: true 
            }
        }
    }
}
