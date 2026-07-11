pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

// Shell Settings: live editor for shell.json. every edit hits the running
// shell at once via ~/.config/ryoku/shell.json (throttled, atomic).
Item {
    id: page

    readonly property var shellKeys: [
        "frameRadius", "frameBorder", "frameSmoothing", "frameOpacity",
        "shadowStrength", "shadowSize", "surfaceColor",
        "osdRadius", "osdOpacity",
        "barEnabled", "barPosition", "barStyle", "barHeight",
        "barShowTitle", "barShowMedia", "barShowStatus", "barOccupiedWorkspaces",
        "fontFamily", "fontScale"
    ]

    readonly property var defaults: ({
        "frameRadius": 9, "frameBorder": 59, "frameSmoothing": 8, "frameOpacity": 1,
        "shadowStrength": 0.63, "shadowSize": 12, "surfaceColor": "#0f1115",
        "osdRadius": 28, "osdOpacity": 1,
        "barEnabled": true, "barPosition": "top", "barStyle": "noctalia", "barHeight": 30,
        "barShowTitle": true, "barShowMedia": true, "barShowStatus": true, "barOccupiedWorkspaces": true,
        "fontFamily": "JetBrainsMono Nerd Font", "fontScale": 1.3
    })

    property string group: "bar"
    property bool shellLoaded: false
    readonly property bool ready: page.shellLoaded
    property var committedVals: ({})

    QtObject {
        id: draft
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

    function sameVal(a, b) { return String(a) === String(b); }

    readonly property bool dirty: {
        if (!page.ready) return false;
        for (var i = 0; i < page.shellKeys.length; i++) {
            var k = page.shellKeys[i];
            if (!page.sameVal(draft[k], page.committedVals[k]))
                return true;
        }
        return false;
    }

    function adopt(adptr) {
        var c = {};
        for (var k in page.committedVals) c[k] = page.committedVals[k];
        for (var i = 0; i < page.shellKeys.length; i++) {
            var kk = page.shellKeys[i];
            draft[kk] = adptr[kk];
            c[kk] = adptr[kk];
        }
        page.committedVals = c;
    }

    function flush() {
        for (var i = 0; i < page.shellKeys.length; i++) {
            var k = page.shellKeys[i];
            shellA[k] = draft[k];
        }
        cfgShell.writeAdapter();
    }

    property bool writePending: false
    Timer {
        id: throttle; interval: 70
        onTriggered: {
            if (page.writePending) { page.writePending = false; page.flush(); throttle.restart(); }
        }
    }
    function edit(k, v) {
        draft[k] = v;
        if (throttle.running) { page.writePending = true; }
        else { page.flush(); throttle.start(); }
    }

    function snapshotDraft() {
        var s = {};
        for (var i = 0; i < page.shellKeys.length; i++) { var k = page.shellKeys[i]; s[k] = draft[k]; }
        return s;
    }
    function save() {
        throttle.stop(); page.writePending = false; page.flush();
        page.committedVals = page.snapshotDraft();
    }
    function revert() {
        throttle.stop(); page.writePending = false;
        for (var i = 0; i < page.shellKeys.length; i++) { var k = page.shellKeys[i]; draft[k] = page.committedVals[k]; }
        page.flush();
    }
    function resetDefaults() {
        for (var i = 0; i < page.shellKeys.length; i++) { var k = page.shellKeys[i]; page.edit(k, page.defaults[k]); }
    }

    FileView {
        id: cfgShell
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ryoku/shell.json"
        blockLoading: true
        watchChanges: false
        printErrors: false
        atomicWrites: true
        onLoaded: { if (!page.shellLoaded) { page.adopt(shellA); page.shellLoaded = true; } }
        onLoadFailed: { if (!page.shellLoaded) { page.adopt(shellA); page.shellLoaded = true; } }

        JsonAdapter {
            id: shellA
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

    Component.onDestruction: {
        if (page.ready && page.dirty) {
            for (var i = 0; i < page.shellKeys.length; i++) { var k = page.shellKeys[i]; shellA[k] = page.committedVals[k]; }
            cfgShell.writeAdapter();
        }
    }

    // tabs
    Segmented {
        id: tabs
        anchors.left: parent.left
        anchors.top: parent.top
        model: [
            { "key": "frame", "label": "Frame" },
            { "key": "bar", "label": "Bar" }
        ]
        current: page.group
        onSelected: (k) => page.group = k
    }

    Text {
        anchors.left: tabs.right
        anchors.leftMargin: 18
        anchors.verticalCenter: tabs.verticalCenter
        text: "Edits show on your desktop as you make them"
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabs.bottom
        anchors.topMargin: 26
        anchors.bottom: bar.top
        anchors.bottomMargin: 18
        contentWidth: width
        contentHeight: Math.max(loader.height, height)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: sb; policy: ScrollBar.AsNeeded; width: 7
            contentItem: Rectangle {
                implicitWidth: 4; radius: Theme.radius
                color: Theme.line
                opacity: sb.pressed ? 0.9 : (sb.hovered ? 0.7 : 0.4)
                Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            }
        }

        Loader {
            id: loader
            width: flick.width - 12
            height: item ? item.implicitHeight : 0
            sourceComponent: page.group === "frame" ? frameComp : barComp
            onLoaded: { if (item) { item.opacity = 0; fade.restart(); } }
        }
        NumberAnimation { id: fade; target: loader.item; property: "opacity"; to: 1; duration: Theme.medium; easing.type: Theme.ease }
    }

    Component {
        id: frameComp
        Column {
            width: parent.width
            spacing: 30

            SettingSection {
                width: parent.width
                title: "SURFACE"
                ColorField {
                    width: Math.min(parent.width, 460); label: "Colour"
                    value: draft.surfaceColor
                    onModified: (v) => page.edit("surfaceColor", v)
                }
                SliderRow {
                    width: Math.min(parent.width, 460); label: "Opacity"; percent: true
                    from: 0.2; to: 1; step: 0.01; value: draft.frameOpacity
                    onModified: (v) => page.edit("frameOpacity", v)
                }
            }
            SettingSection {
                width: parent.width
                title: "TEXT"
                Dropdown {
                    width: Math.min(parent.width, 460); label: "Font"
                    fieldWidth: 200
                    options: ["Inter", "JetBrainsMono Nerd Font", "Noto Sans", "Noto Sans CJK JP"]
                    current: draft.fontFamily
                    onChosen: (k) => page.edit("fontFamily", k)
                }
                SliderRow {
                    width: Math.min(parent.width, 460); label: "Size"; percent: true
                    from: 0.7; to: 1.6; step: 0.05; value: draft.fontScale
                    onModified: (v) => page.edit("fontScale", v)
                }
            }
        }
    }

    Component {
        id: barComp
        Column {
            width: parent.width
            spacing: 30

            SettingSection {
                width: parent.width
                title: "BAR"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable bar"
                    checked: draft.barEnabled
                    onToggled: (v) => page.edit("barEnabled", v)
                }
                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Position"
                    options: [{ "key": "top", "label": "Top" }, { "key": "bottom", "label": "Bottom" }]
                    current: draft.barPosition
                    onChosen: (k) => page.edit("barPosition", k)
                }
                Dropdown {
                    width: Math.min(parent.width, 460); label: "Style"
                    fieldWidth: 170
                    options: [
                        { "key": "noctalia", "label": "Noctalia", "hint": "pill · dot" },
                        { "key": "caelestia", "label": "Caelestia", "hint": "cell strip" },
                        { "key": "aegis", "label": "Aegis", "hint": "instrument" },
                        { "key": "stele", "label": "Stele", "hint": "engraved" },
                        { "key": "triptych", "label": "Triptych", "hint": "islands" }
                    ]
                    current: draft.barStyle
                    onChosen: (k) => page.edit("barStyle", k)
                }
                NumberField {
                    width: Math.min(parent.width, 460); label: "Thickness"; unit: "px"
                    from: 18; to: 48; value: draft.barHeight
                    onModified: (v) => page.edit("barHeight", v)
                }
                Text {
                    width: Math.min(parent.width, 620)
                    wrapMode: Text.WordWrap
                    text: "A bar riding the top or bottom edge. Noctalia (pill and dot) and Caelestia (numbered cell strip) are carried from their namesake shells; Aegis is a flat instrument panel with hairline accent underlines, Stele an engraved strip of bracketed cells, and Triptych groups modules into three islands."
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }

            SettingSection {
                width: parent.width
                title: "CONTENT"
                ToggleRow { width: Math.min(parent.width, 460); label: "Focused window title"; checked: draft.barShowTitle; onToggled: (v) => page.edit("barShowTitle", v) }
                ToggleRow { width: Math.min(parent.width, 460); label: "Now playing"; checked: draft.barShowMedia; onToggled: (v) => page.edit("barShowMedia", v) }
                ToggleRow { width: Math.min(parent.width, 460); label: "Status glyphs (network, battery, inbox)"; checked: draft.barShowStatus; onToggled: (v) => page.edit("barShowStatus", v) }
                ToggleRow { width: Math.min(parent.width, 460); label: "Only occupied workspaces"; checked: draft.barOccupiedWorkspaces; onToggled: (v) => page.edit("barOccupiedWorkspaces", v) }
            }
        }
    }

    // action bar
    Rectangle {
        id: bar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        height: 60
        radius: Theme.radius
        color: page.dirty ? Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, 0.08) : Theme.surfaceLo
        border.width: 1
        border.color: page.dirty ? Qt.rgba(Theme.ember.r, Theme.ember.g, Theme.ember.b, 0.4) : Theme.line
        Behavior on color { ColorAnimation { duration: Theme.medium } }
        Behavior on border.color { ColorAnimation { duration: Theme.medium } }

        Rectangle {
            id: statusDot
            anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter
            width: 9; height: 9; radius: 4.5
            color: page.dirty ? Theme.ember : Theme.ok
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        Text {
            anchors.left: statusDot.right; anchors.leftMargin: 11; anchors.verticalCenter: parent.verticalCenter
            text: page.dirty ? "Previewing unsaved changes" : "Saved · live on your desktop"
            color: page.dirty ? Theme.bright : Theme.dim
            font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            HubButton { anchors.verticalCenter: parent.verticalCenter; label: "Reset to defaults"; icon: "refresh"; onClicked: page.resetDefaults() }
            HubButton { anchors.verticalCenter: parent.verticalCenter; label: "Revert"; icon: "close"; enabled: page.dirty; onClicked: page.revert() }
            HubButton { anchors.verticalCenter: parent.verticalCenter; label: "Save"; icon: "check"; primary: true; enabled: page.dirty; onClicked: page.save() }
        }
    }
}
