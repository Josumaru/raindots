import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property string title: ""
    property string tooltip: ""
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    Layout.topMargin: 4
    spacing: 2

    RowLayout {
        ContentSubsectionLabel {
            visible: root.title && root.title.length > 0
            text: root.title
        }
        Icon {
            visible: root.tooltip && root.tooltip.length > 0
            name: "info"
            size: Appearance.font.pixelSize.large
            
            tint: Appearance.colors.colSubtext
            MouseArea {
                id: infoMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.WhatsThisCursor
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: infoMouseArea.containsMouse
                    text: root.tooltip
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 2
    }
}
