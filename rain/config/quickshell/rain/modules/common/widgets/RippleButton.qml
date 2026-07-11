import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls

Button {
    id: root
    property bool toggled
    property string buttonText
    property bool pointingHandCursor: true
    property real buttonRadius: Appearance?.rounding?.small ?? 4
    property var downAction
    property var releaseAction
    property var altAction
    property var middleClickAction

    property color colBackground: ColorUtils.transparentize(Appearance?.colors.colLayer1Hover, 1) || "transparent"
    property color colBackgroundHover: Appearance?.colors.colLayer1Hover ?? "#E5DFED"
    property color colBackgroundToggled: Appearance?.colors.colPrimary ?? "#65558F"
    property color colBackgroundToggledHover: Appearance?.colors.colPrimaryHover ?? "#77699C"
    property color colRipple: "transparent"
    property color colRippleToggled: "transparent"
    property real buttonRadiusPressed: 0

    property bool showBorder: false
    property color colBorder: Appearance?.m3colors.m3outline ?? "#948f94"
    property color colBorderHover: Appearance?.colors.colPrimary ?? "#65558F"

    property real pressScale: 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutExpo } }

    opacity: root.enabled ? 1 : 0.4
    scale: root.down ? root.pressScale : 1

    property color buttonColor: root.toggled ?
        (root.hovered ? colBackgroundToggledHover : colBackgroundToggled) :
        (root.hovered ? colBackgroundHover : colBackground)

    MouseArea {
        anchors.fill: parent
        cursorShape: root.pointingHandCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: (event) => {
            if (event.button === Qt.RightButton) {
                if (root.altAction) root.altAction(event);
                return;
            }
            if (event.button === Qt.MiddleButton) {
                if (root.middleClickAction) root.middleClickAction();
                return;
            }
            root.down = true
            if (root.downAction) root.downAction();
        }
        onReleased: (event) => {
            root.down = false
            if (event.button != Qt.LeftButton) return;
            if (root.releaseAction) root.releaseAction();
            root.click()
        }
        onCanceled: { root.down = false }
    }

    background: Rectangle {
        id: buttonBackground
        radius: root.buttonRadius
        implicitHeight: 30

        color: root.buttonColor
        Behavior on color {
            animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        border.width: root.showBorder ? (root.hovered || root.toggled ? 1 : 0) : 0
        border.color: (root.toggled || root.hovered) ? root.colBorderHover : root.colBorder
        Behavior on border.width { NumberAnimation { duration: 120 } }
        Behavior on border.color {
            animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    contentItem: StyledText {
        text: root.buttonText
        color: root.toggled ? Appearance?.colors.colOnPrimary ?? "#FFFFFF" : Appearance?.colors.colOnLayer1 ?? "#000000"
        Behavior on color {
            animation: Appearance?.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
