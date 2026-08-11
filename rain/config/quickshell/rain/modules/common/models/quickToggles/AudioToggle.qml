import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Audio output")
    statusText: toggled ? Translation.tr("Unmuted") : Translation.tr("Muted")
    tooltipText: Translation.tr("Audio output | Right-click for volume mixer & device selector")
    toggled: !Audio.sink?.audio?.muted
    icon: Audio.sink?.audio?.muted ? "speaker_muted" : "volume_up"
    mainAction: () => {
        Audio.toggleMute()
    }
    hasMenu: true
}
