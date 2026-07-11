pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// reads wallust-generated palette at ~/.cache/wallust/colors.json.
// feeds Theme.qml when Config.matchWallpaper is true.
Item {
    id: wallust

    property color accent: "#e2342a"
    property color base:   "#16110b"
    property color deep:   "#0f0c07"
    property color elevated: "#1b150e"
    property color line:   Qt.rgba(243/255, 237/255, 225/255, 0.14)

    property string rawJson: ""

    FileView {
        id: file
        path: (Quickshell.env("HOME") || "") + "/.cache/wallust/colors.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: parse()
        onLoadFailed: {}

        function parse() {
            try {
                var c = JSON.parse(file.text());
                if (!c) return;
                if (c.color1) wallust.accent = c.color1;
                if (c.background) wallust.base = c.background;
                if (c.color0) wallust.deep = c.color0;
                if (c.color7) wallust.elevated = c.color7;
                if (c.color8) wallust.line = c.color8;
            } catch(e) {}
        }
    }

    Component.onCompleted: if (file.text()) file.parse();
}
