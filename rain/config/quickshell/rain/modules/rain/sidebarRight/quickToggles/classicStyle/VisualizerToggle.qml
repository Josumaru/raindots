import qs.modules.common.widgets
import qs
import qs.services
import QtQuick
import Quickshell

QuickToggleButton {
    id: root
    visible: Visualizer.available
    toggled: Config.ready && Config.options.background.widgets.visualizer.enable
    buttonIcon: "equalizer"

    onClicked: {
        Config.options.background.widgets.visualizer.enable = !Config.options.background.widgets.visualizer.enable
    }

    altAction: () => {
        GlobalStates.sidebarRightOpen = false
        Quickshell.execDetached([Directories.rainBin, "hub"])
    }

    StyledToolTip {
        text: Translation.tr("Equalizer | Right-click to open settings")
    }
}
