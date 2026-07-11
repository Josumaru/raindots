pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// reads wallust palette for wallpaper previews in the hub.
Item {
    id: wallust

    property color accent: "#e2342a"
    property string rawJson: ""

    FileView {
        id: file
        path: (Quickshell.env("HOME") || "") + "/.cache/wallust/colors.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: parse()

        function parse() {
            try {
                var c = JSON.parse(file.text());
                if (c && c.color1) wallust.accent = c.color1;
            } catch(e) {}
        }
    }

    Component.onCompleted: { if (file.text()) file.parse(); }
}
