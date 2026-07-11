pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// live shell config: reads ~/.config/ryoku/shell.json, watched for changes.
// the hub's ShellSettingsPage writes this file; the bar reacts live.
Item {
    id: root

    property alias frameRadius:    adapter.frameRadius
    property alias frameBorder:    adapter.frameBorder
    property alias frameSmoothing: adapter.frameSmoothing
    property alias frameOpacity:   adapter.frameOpacity
    property alias shadowStrength: adapter.shadowStrength
    property alias shadowSize:     adapter.shadowSize
    property alias surfaceColor:   adapter.surfaceColor
    property alias osdRadius:      adapter.osdRadius
    property alias osdOpacity:     adapter.osdOpacity

    property alias barEnabled:            adapter.barEnabled
    property alias barPosition:           adapter.barPosition
    property alias barStyle:              adapter.barStyle
    property alias barHeight:             adapter.barHeight
    property alias barShowTitle:          adapter.barShowTitle
    property alias barShowMedia:          adapter.barShowMedia
    property alias barShowStatus:         adapter.barShowStatus
    property alias barOccupiedWorkspaces: adapter.barOccupiedWorkspaces

    property alias fontFamily: adapter.fontFamily
    property alias fontScale:  adapter.fontScale

    property bool ready: false
    property alias matchWallpaper: themeAdapter.followWallpaper

    FileView {
        id: file
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ryoku/shell.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property real frameRadius: 9
            property real frameBorder: 59
            property real frameSmoothing: 8
            property real frameOpacity: 1
            property real shadowStrength: 0.63
            property real shadowSize: 12
            property color surfaceColor: "#0f1115"
            property real osdRadius: 28
            property real osdOpacity: 1
            property bool barEnabled: true
            property string barPosition: "top"
            property string barStyle: "noctalia"
            property real barHeight: 30
            property bool barShowTitle: true
            property bool barShowMedia: true
            property bool barShowStatus: true
            property bool barOccupiedWorkspaces: true
            property string fontFamily: "JetBrainsMono Nerd Font"
            property real fontScale: 1.3
        }
    }

    FileView {
        id: themeFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ryoku/theme.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter { id: themeAdapter; property bool followWallpaper: true }
    }

    function persist() { file.writeAdapter(); }

    Component.onCompleted: {
        if (!file.text()) file.writeAdapter();
        root.ready = true;
    }
}
