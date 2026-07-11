import qs.modules.common
import QtQuick
import QtQuick.Controls

TextField {
    id: root
    renderType: Text.QtRendering

    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    placeholderTextColor: Appearance.m3colors.m3outline
    clip: true

    background: Rectangle {
        implicitHeight: 40
        color: Appearance.m3colors.m3surfaceContainerLow
        radius: 0
        border.width: root.activeFocus ? 1 : (root.hovered ? 1 : 0)
        border.color: root.activeFocus ? Appearance.colors.colPrimary :
            root.hovered ? Appearance.m3colors.m3outline : "transparent"
        Behavior on border.width { NumberAnimation { duration: 120 } }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    wrapMode: TextEdit.Wrap
    color: Appearance.m3colors.m3onSurface

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}
