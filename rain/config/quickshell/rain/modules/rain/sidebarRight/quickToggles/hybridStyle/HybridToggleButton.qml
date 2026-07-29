import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

GroupButton {
    id: root

    required property QuickToggleModel toggleModel
    required property string toggleType
    property string buttonIcon: toggleModel.icon ?? "close"

    property bool editMode: false
    property int buttonIndex: -1
    property var buttonData: null

    toggled: toggleModel.toggled ?? false
    enabled: (toggleModel.available ?? true) || editMode
    altAction: toggleModel.hasMenu ? () => root.openMenu() : (toggleModel.altAction ?? null)

    property real cellSize: 40
    baseWidth: cellSize
    baseHeight: cellSize
    clickedWidth: baseWidth + Math.min(20, cellSize * 0.5)
    buttonRadius: Appearance?.rounding.normal
    buttonRadiusPressed: Appearance?.rounding?.small

    opacity: editMode && !toggleModel.available ? 0.4 : 1

    onClicked: {
        if (!editMode) toggleModel.mainAction()
    }

    signal openMenu()

    contentItem: Icon {
        anchors.centerIn: parent
        size: Math.min(22, root.cellSize * 0.55)
        tint: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        name: root.buttonIcon
    }

    MouseArea {
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        function toggleEnabled() {
            const index = root.buttonIndex
            const toggleList = Config.options.sidebar.quickToggles.android.toggles
            const buttonType = root.buttonData.type
            if (!toggleList.find(toggle => toggle.type === buttonType)) {
                toggleList.push({ type: buttonType, size: 1 })
            } else {
                toggleList.splice(index, 1)
            }
        }

        function movePositionBy(offset) {
            const index = root.buttonIndex
            const toggleList = Config.options.sidebar.quickToggles.android.toggles
            const buttonType = root.buttonData.type
            const targetIndex = index + offset
            if (!toggleList.find(toggle => toggle.type === buttonType)) return
            if (targetIndex < 0 || targetIndex >= toggleList.length) return
            const temp = toggleList[index]
            toggleList[index] = toggleList[targetIndex]
            toggleList[targetIndex] = temp
        }

        onReleased: (event) => {
            if (event.button === Qt.LeftButton)
                toggleEnabled()
        }
        onPressAndHold: {
            toggleEnabled()
        }
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                movePositionBy(1)
            else if (event.angleDelta.y > 0)
                movePositionBy(-1)
            event.accepted = true
        }
    }

    StyledToolTip {
        text: toggleModel.tooltipText ?? ""
    }
}
