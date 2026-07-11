//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import Quickshell.Wayland

// Hub root: floating window that can be moved/resized by the compositor.
// The Hyprland window rule floats and centres it. `qs -c hub` loads this.
ShellRoot {
    FloatingWindow {
        id: win
        title: "raindots"
        implicitWidth: 1360
        implicitHeight: 880
        minimumSize: Qt.size(900, 600)

        // Quit on close so process/lock always releases (see ryoku-arch notes).
        onClosed: Qt.quit()

        Hub {
            anchors.fill: parent
        }
    }
}
