pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string home: Quickshell.env("HOME") || "/home/unknown"
    readonly property string xdgConfig: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string rainBin: Quickshell.env("RAIN_BIN") || xdgConfig + "/rain/bin/rain"
}
