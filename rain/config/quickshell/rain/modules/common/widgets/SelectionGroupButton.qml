import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

GroupButton {
    id: root
    horizontalPadding: 12
    verticalPadding: 8
    property string buttonIcon
    property bool leftmost: false
    property bool rightmost: false
    leftRadius: (toggled || leftmost) ? buttonRadius : 0
    rightRadius: (toggled || rightmost) ? buttonRadius : 0
    colBackground: Appearance.colors.colSecondaryContainer
    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
    colBackgroundActive: Appearance.colors.colSecondaryContainerActive

    scale: root.down ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutExpo } }

    contentItem: RowLayout {
        spacing: 4 * (root.buttonText?.length > 0)

        Loader {
            Layout.alignment: Qt.AlignVCenter
            active: root.buttonIcon && root.buttonIcon.length > 0
            visible: active
            sourceComponent: Item {
                implicitWidth: materialSymbol.implicitWidth
                Icon {
                    id: materialSymbol
                    name: root.buttonIcon
                    size: Appearance.font.pixelSize.larger
                    tint: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                }
            }
        }

        Item {
            implicitWidth: root.buttonText?.length > 0 ? textItem.implicitWidth : 0
            implicitHeight: textMetrics.height

            TextMetrics {
                id: textMetrics
                font.family: Appearance.font.family.main
                text: "Abc"
            }

            StyledText {
                id: textItem
                anchors.centerIn: parent
                color: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                text: root.buttonText
            }
        }
    }
}
