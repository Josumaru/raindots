pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

// Appearance: theme picker + look controls. edit live via `rain hub hypr` commands.
Item {
    id: page

    property string group: "themes"
    property var cursorThemes: []

    Process {
        id: cursorsProc
        command: [Directories.rainBin, "hub", "hypr", "cursors"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.cursorThemes = JSON.parse(this.text); } catch (e) {}
            }
        }
    }

    // wallpaper
    readonly property string wpDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var wallpapers: []
    property string currentWall: ""

    function refreshWalls() { wallListProc.running = true; wallStateProc.running = true; }
    function applyWall(p) {
        page.currentWall = p;
        Quickshell.execDetached([Directories.rainBin, "wallpaper", "set", p]);
    }

    Process {
        id: wallListProc
        command: ["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%T@\\t%p\\n' | sort -rn", "_", page.wpDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n"), out = [];
                for (var i = 0; i < lines.length; i++) {
                    var tab = lines[i].indexOf("\t");
                    if (tab < 1) continue;
                    var p = lines[i].substring(tab + 1);
                    out.push({ "path": p, "name": p.substring(p.lastIndexOf("/") + 1) });
                }
                page.wallpapers = out;
            }
        }
    }
    Process {
        id: wallStateProc
        command: ["sh", "-c", "cat \"$1\" 2>/dev/null || true", "_", Quickshell.env("HOME") + "/.local/state/rain-wallpaper"]
        stdout: StdioCollector { onStreamFinished: page.currentWall = this.text.trim() }
    }

    Process { id: wallNextProc; command: [Directories.rainBin, "wallpaper", "next"] }

    property string scheme: "follow"
    function setScheme(k) {
        page.scheme = k;
        Quickshell.execDetached([Directories.rainBin, "hub", "hypr", "scheme", k]);
    }

    onGroupChanged: {
        if (page.group === "wallpaper") page.refreshWalls();
    }
    Component.onCompleted: page.refreshWalls()

    Segmented {
        id: tabs
        anchors.left: parent.left
        anchors.top: parent.top
        model: [
            { "key": "themes", "label": "Themes" },
            { "key": "look", "label": "Look" },
            { "key": "cursor", "label": "Cursor" },
            { "key": "wallpaper", "label": "Wallpaper" }
        ]
        current: page.group
        onSelected: (k) => page.group = k
    }

    Text {
        anchors.left: tabs.right; anchors.leftMargin: 18; anchors.verticalCenter: tabs.verticalCenter
        text: "Edits show on your desktop as you make them"
        color: Theme.faint; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
    }

    Flickable {
        id: flick
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: tabs.bottom; anchors.topMargin: 26
        anchors.bottom: parent.bottom; anchors.bottomMargin: 18
        contentWidth: width
        contentHeight: Math.max(loader.height, height)
        clip: true; boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: sb; policy: ScrollBar.AsNeeded; width: 7
            contentItem: Rectangle {
                implicitWidth: 4; radius: Theme.radius; color: Theme.line
                opacity: sb.pressed ? 0.9 : (sb.hovered ? 0.7 : 0.4)
                Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            }
        }

        Loader {
            id: loader; width: flick.width - 12
            height: item ? item.implicitHeight : 0
            sourceComponent: page.group === "themes" ? themeComp : page.group === "look" ? lookComp : page.group === "cursor" ? cursorComp : wallpaperComp
            onLoaded: { if (item) { item.opacity = 0; fade.restart(); } }
        }
        NumberAnimation { id: fade; target: loader.item; property: "opacity"; to: 1; duration: Theme.medium; easing.type: Theme.ease }
    }

    Component { id: themeComp; ThemesPage {} }

    Component {
        id: lookComp
        Column {
            width: parent.width; spacing: 30

            SettingSection {
                width: parent.width; title: "SHAPE"
                NumberField {
                    width: Math.min(parent.width, 460); label: "Corner radius"; unit: "px"
                    from: 0; to: 30; value: 8
                    onModified: (v) => Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", String(v)])
                }
                NumberField {
                    width: Math.min(parent.width, 460); label: "Border thickness"; unit: "px"
                    from: 0; to: 12; value: 2
                    onModified: (v) => Quickshell.execDetached(["hyprctl", "keyword", "general:border_size", String(v)])
                }
            }
            SettingSection {
                width: parent.width; title: "GAPS"
                NumberField {
                    width: Math.min(parent.width, 460); label: "Inner (between windows)"; unit: "px"
                    from: 0; to: 40; value: 5
                    onModified: (v) => Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", String(v)])
                }
                NumberField {
                    width: Math.min(parent.width, 460); label: "Outer (screen edge)"; unit: "px"
                    from: 0; to: 60; value: 10
                    onModified: (v) => Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", String(v)])
                }
            }
            Text {
                width: Math.min(parent.width, 620); wrapMode: Text.WordWrap
                text: "These edits apply live to your desktop. Save in the Hub or directly in your Hyprland config to make them permanent."
                color: Theme.faint; font.family: Theme.font; font.pixelSize: 12
            }
        }
    }

    Component {
        id: cursorComp
        Column {
            width: parent.width; spacing: 30
            SettingSection {
                width: parent.width; title: "CURSOR"
                NumberField {
                    width: Math.min(parent.width, 460); label: "Size"; unit: "px"
                    from: 12; to: 64; step: 4; value: 24
                    onModified: (v) => Quickshell.execDetached(["hyprctl", "keyword", "cursor:no_hardware_cursors", "false"])
                }
                Text {
                    width: Math.min(parent.width, 620); wrapMode: Text.WordWrap
                    text: "Cursor theme is read from your installed icon sets. Use Hyprland config for persistent changes."
                    color: Theme.dim; font.family: Theme.font; font.pixelSize: 12
                }
            }
        }
    }

    Component {
        id: wallpaperComp
        Column {
            width: parent.width; spacing: 22
            SettingSection {
                width: parent.width; title: "WALLPAPER"
                Row {
                    width: parent.width; spacing: 12
                    Text {
                        width: parent.width - shuffleBtn.width - 12; anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.WordWrap
                        text: "Pick a wallpaper to retheme the desktop."
                        color: Theme.dim; font.family: Theme.font; font.pixelSize: 12
                    }
                    HubButton {
                        id: shuffleBtn; anchors.verticalCenter: parent.verticalCenter
                        label: "Shuffle"; icon: "refresh"
                        onClicked: wallNextProc.running = true
                    }
                }
                Flow {
                    width: parent.width; spacing: 12
                    Repeater {
                        model: page.wallpapers
                        delegate: Rectangle {
                            id: wp
                            required property var modelData
                            readonly property bool active: page.currentWall === wp.modelData.path
                            width: 172; height: 104; radius: Theme.radius
                            color: Theme.surfaceLo
                            border.width: wp.active ? 2 : 1
                            border.color: wp.active ? Theme.ember : (wpHov.hovered ? Theme.cream : Theme.line)
                            clip: true
                            Behavior on border.color { ColorAnimation { duration: Theme.quick } }

                            Image {
                                anchors.fill: parent; anchors.margins: 2
                                source: "file://" + wp.modelData.path
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 360; sourceSize.height: 220
                                asynchronous: true; cache: false
                            }
                            HoverHandler { id: wpHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: page.applyWall(wp.modelData.path) }
                            scale: wpHov.hovered ? 1.03 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.quick; easing.type: Theme.ease } }
                        }
                    }
                }
                Text {
                    visible: page.wallpapers.length === 0
                    text: "No wallpapers in ~/Pictures/Wallpapers."
                    color: Theme.faint; font.family: Theme.font; font.pixelSize: 13
                }
            }
        }
    }
}
