import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TabButton {
    id: root
    property string buttonText
    property string buttonIcon

    property color colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
    property color colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnSurface, root.checked ? 1 : 0.95)

    PointingHandInteraction {}

    scale: root.down ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutExpo } }

    background: Rectangle {
        id: buttonBackground
        anchors {
            fill: parent
            margins: 3
        }
        implicitHeight: 42
        color: (root.hovered ? root.colBackgroundHover : root.colBackground)
        border.width: root.checked ? 1 : (root.hovered ? 1 : 0)
        border.color: root.checked ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
        Behavior on border.width { NumberAnimation { duration: 120 } }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    contentItem: Item {
        anchors.centerIn: buttonBackground
        RowLayout {
            anchors.centerIn: parent
            spacing: 0

            Loader {
                id: iconLoader
                active: buttonIcon?.length > 0
                sourceComponent: buttonIcon?.length > 0 ? materialSymbolComponent : null
                Layout.rightMargin: 5
            }

            Component {
                id: materialSymbolComponent
                Icon {
                    name: buttonIcon
                    size: Appearance.font.pixelSize.huge
                    tint: root.checked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    Behavior on tint {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
            StyledText {
                id: buttonTextWidget
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.checked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                text: buttonText
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }
    }
}
