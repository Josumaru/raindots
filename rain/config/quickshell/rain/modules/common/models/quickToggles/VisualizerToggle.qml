import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Equalizer")

    available: Visualizer.available
    toggled: Config.ready && Config.options.background.widgets.visualizer.enable
    statusText: toggled ? Translation.tr("On") : Translation.tr("Off")
    icon: "equalizer"
    hasMenu: false

    mainAction: () => {
        Config.options.background.widgets.visualizer.enable = !Config.options.background.widgets.visualizer.enable
    }

    altAction: () => {
        GlobalStates.sidebarRightOpen = false
        Quickshell.execDetached([Directories.rainBin, "hub"])
    }

    tooltipText: Translation.tr("Equalizer | Right-click to open settings")
}