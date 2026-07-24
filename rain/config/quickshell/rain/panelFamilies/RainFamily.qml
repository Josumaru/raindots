import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.rain.background
import qs.modules.rain.bar
import qs.modules.rain.cheatsheet
import qs.modules.rain.dock
import qs.modules.rain.lock
import qs.modules.rain.mediaControls
import qs.modules.rain.notificationPopup
import qs.modules.rain.onScreenDisplay
import qs.modules.rain.onScreenKeyboard
import qs.modules.rain.overview
import qs.modules.rain.polkit
import qs.modules.rain.regionSelector
import qs.modules.rain.screenCorners
import qs.modules.rain.screenTranslator
import qs.modules.rain.sessionScreen
import qs.modules.rain.sidebarLeft
import qs.modules.rain.sidebarRight
import qs.modules.rain.overlay
import qs.modules.rain.verticalBar
import qs.modules.rain.wallpaperSelector
import qs.modules.rain.wallpaperPickerLauncher

Scope {
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { extraCondition: Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { component: WallpaperSelector {} }
    PanelLoader { component: WallpaperPickerLauncher {} }
}
