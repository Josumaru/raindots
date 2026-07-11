import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: buttonWithIconRoot
    property string nerdIcon
    property string materialIcon
    property bool materialIconFill: true
    property string mainText: "Button text"
    property Component mainContentComponent: Component {
        StyledText {
            visible: text !== ""
            text: buttonWithIconRoot.mainText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
    implicitHeight: 35
    horizontalPadding: 10
    buttonRadius: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2

    contentItem: RowLayout {
        Item {
            Layout.fillWidth: false
            implicitWidth: Math.max(materialIconLoader.implicitWidth, nerdIconLoader.implicitWidth)
            Loader {
                id: materialIconLoader
                anchors.centerIn: parent
                active: !nerdIcon
                sourceComponent: Icon {
                    name: buttonWithIconRoot.materialIcon
                    size: Appearance.font.pixelSize.larger
                    tint: Appearance.colors.colOnSecondaryContainer
                }
            }
            Loader {
                id: nerdIconLoader
                anchors.centerIn: parent
                active: nerdIcon
                sourceComponent: StyledText {
                    text: buttonWithIconRoot.nerdIcon
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.family: Appearance.font.family.iconNerd
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
        Loader {
            Layout.fillWidth: true
            sourceComponent: buttonWithIconRoot.mainContentComponent
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
