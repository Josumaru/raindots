import QtQuick
import QtQuick.Controls
import Quickshell
import "."

FloatingWindow {
    id: root
    visible: true
    title: "wallpaper-picker"
    color: "transparent"

    onVisibleChanged: {
        if (!visible) {
            Qt.quit()
        }
    }

    implicitWidth: Math.round(Screen.width * 0.94)
    implicitHeight: Math.round(Screen.height * 0.30)

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            Qt.quit()
            event.accepted = true
        }
    }

    WallpaperPicker {
        anchors.fill: parent
        focus: true
    }
}
