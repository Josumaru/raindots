pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property string rainBin: Quickshell.env("RAIN_BIN") || "rain"
}
