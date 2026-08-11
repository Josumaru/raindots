import qs.services
import QtQuick
import qs.modules.rain.onScreenDisplay

OsdValueIndicator {
    id: osdValues
    value: Audio.sink?.audio.volume ?? 0
    icon: Audio.sink?.audio.muted ? "speaker_muted" : "volume_up"
    name: Translation.tr("Volume")
}
