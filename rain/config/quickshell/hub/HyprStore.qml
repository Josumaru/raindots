pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "Singletons"

// shared engine behind every Lua-editing settings page. loads the full override
// document from the `rain hub hypr` backend, holds an editable draft as plain
// reactive properties, previews scalar edits live (via hyprctl eval),
// persists on save (which regenerates settings.lua and reloads).
Item {
    id: store

    property bool ready: false
    property var committed: ({})
    property var defaults: ({})

    // draft: appearance
    property int gapsIn: 12
    property int gapsOut: 18
    property int borderSize: 2
    property int rounding: 2
    property real roundingPower: 4
    property real activeOpacity: 1
    property real inactiveOpacity: 0.94
    property bool dimInactive: false
    property real dimStrength: 0.5
    property bool blurEnabled: true
    property int blurSize: 4
    property int blurPasses: 1
    property bool blurXray: false
    property real blurVibrancy: 0.17
    property real blurNoise: 0.01
    property bool shadowEnabled: true
    property int shadowRange: 45
    property int shadowPower: 4
    property bool glowEnabled: false
    property int glowRange: 10
    property string glowColor: "#ee33cc"
    property bool animations: true
    property string layout: "dwindle"
    property string activeBorder: "#e0563b"
    property string inactiveBorder: "#313a4d"
    property bool resizeOnBorder: true
    property bool snapEnabled: false
    property bool wobblyWindows: false
    property string windowStyle: "pop"
    property bool animatedBorder: false
    property real borderAngleSpeed: 3

    // draft: input
    property string kbLayout: "us"
    property string kbVariant: ""
    property string kbOptions: ""
    property bool numlockByDefault: false
    property int followMouse: 2
    property real sensitivity: 0
    property string accelProfile: ""
    property bool leftHanded: false
    property bool mouseNaturalScroll: false
    property real mouseScrollFactor: 1
    property bool middleClickPaste: true
    property bool naturalScroll: false
    property bool tapToClick: true
    property bool tapAndDrag: true
    property bool clickfinger: false
    property bool middleEmulation: false
    property real touchScrollFactor: 1
    property bool disableWhileTyping: true
    property int repeatRate: 25
    property int repeatDelay: 600
    property bool workspaceSwipe: false
    property int swipeFingers: 3
    property bool swipeInvert: true
    property bool swipeCreateNew: true
    property int swipeDistance: 300

    // draft: cursor
    property string cursorTheme: "Bibata-Modern-Ice"
    property int cursorSize: 24
    property int cursorInactiveTimeout: 0
    property bool cursorHideOnKeyPress: false

    // draft: lists
    property var env: []
    property var windowRules: []
    property var layerRules: []
    property var autostart: []
    property var keybinds: []
    property var animItems: []
    property var animCurves: []

    property int rev: 0

    readonly property var appearanceKeys: [
        "gapsIn", "gapsOut", "borderSize", "rounding", "roundingPower",
        "activeOpacity", "inactiveOpacity", "dimInactive", "dimStrength",
        "blurEnabled", "blurSize", "blurPasses", "blurXray", "blurVibrancy", "blurNoise",
        "shadowEnabled", "shadowRange", "shadowPower",
        "glowEnabled", "glowRange", "glowColor",
        "animations", "layout", "activeBorder", "inactiveBorder",
        "resizeOnBorder", "snapEnabled",
        "wobblyWindows", "windowStyle", "animatedBorder", "borderAngleSpeed"
    ]
    readonly property var inputKeys: [
        "kbLayout", "kbVariant", "kbOptions", "numlockByDefault",
        "followMouse", "sensitivity", "accelProfile", "leftHanded",
        "mouseNaturalScroll", "mouseScrollFactor", "middleClickPaste",
        "naturalScroll", "tapToClick", "tapAndDrag", "clickfinger",
        "middleEmulation", "touchScrollFactor", "disableWhileTyping",
        "repeatRate", "repeatDelay",
        "workspaceSwipe", "swipeFingers", "swipeInvert", "swipeCreateNew", "swipeDistance"
    ]
    readonly property var cursorKeys: ["theme", "size", "inactiveTimeout", "hideOnKeyPress"]

    function cursorProp(k) { return "cursor" + k.charAt(0).toUpperCase() + k.slice(1); }

    function snapshot() {
        var a = {}, i = {}, c = {};
        for (var n = 0; n < store.appearanceKeys.length; n++)
            a[store.appearanceKeys[n]] = store[store.appearanceKeys[n]];
        for (n = 0; n < store.inputKeys.length; n++)
            i[store.inputKeys[n]] = store[store.inputKeys[n]];
        for (n = 0; n < store.cursorKeys.length; n++)
            c[store.cursorKeys[n]] = store[store.cursorProp(store.cursorKeys[n])];
        return {
            "appearance": a, "input": i, "cursor": c,
            "env": store.env, "windowRules": store.windowRules, "layerRules": store.layerRules,
            "autostart": store.autostart, "keybinds": store.keybinds,
            "anim": { "items": store.animItems, "curves": store.animCurves }
        };
    }

    function adopt(o) {
        var a = o.appearance || {}, i = o.input || {}, c = o.cursor || {};
        for (var n = 0; n < store.appearanceKeys.length; n++)
            if (a[store.appearanceKeys[n]] !== undefined)
                store[store.appearanceKeys[n]] = a[store.appearanceKeys[n]];
        for (n = 0; n < store.inputKeys.length; n++)
            if (i[store.inputKeys[n]] !== undefined)
                store[store.inputKeys[n]] = i[store.inputKeys[n]];
        for (n = 0; n < store.cursorKeys.length; n++)
            if (c[store.cursorKeys[n]] !== undefined)
                store[store.cursorProp(store.cursorKeys[n])] = c[store.cursorKeys[n]];
        store.env = o.env || []; store.windowRules = o.windowRules || []; store.layerRules = o.layerRules || [];
        store.autostart = o.autostart || []; store.keybinds = o.keybinds || [];
        var an = o.anim || {};
        store.animItems = an.items || []; store.animCurves = an.curves || [];
        store.rev++;
    }

    readonly property bool dirty: {
        void store.rev;
        return store.ready && JSON.stringify(store.snapshot()) !== JSON.stringify(store.committed);
    }

    function edit(key, value) {
        store[key] = value;
        store.rev++;
        store.queuePreview();
    }
    function editList(key, arr) {
        store[key] = arr;
        store.rev++;
    }

    property bool previewPending: false
    Timer {
        id: throttle
        interval: 80
        onTriggered: {
            if (store.previewPending) {
                store.previewPending = false;
                store.previewNow();
                throttle.restart();
            }
        }
    }
    function queuePreview() {
        if (throttle.running) {
            store.previewPending = true;
        } else {
            store.previewNow();
            throttle.start();
        }
    }
    function previewNow() {
        previewProc.command = [Directories.rainBin, "hub", "hypr", "preview", JSON.stringify(store.snapshot())];
        previewProc.running = true;
    }

    function save() {
        throttle.stop();
        store.previewPending = false;
        saveProc.command = [Directories.rainBin, "hub", "hypr", "save", JSON.stringify(store.snapshot())];
        saveProc.running = true;
        store.committed = JSON.parse(JSON.stringify(store.snapshot()));
        store.rev++;
    }
    function revert() {
        throttle.stop();
        store.previewPending = false;
        store.adopt(store.committed);
        restoreProc.command = [Directories.rainBin, "hub", "hypr", "restore"];
        restoreProc.running = true;
    }

    function resetAppearance() {
        var a = store.defaults.appearance || {}, c = store.defaults.cursor || {};
        for (var n = 0; n < store.appearanceKeys.length; n++)
            if (a[store.appearanceKeys[n]] !== undefined)
                store[store.appearanceKeys[n]] = a[store.appearanceKeys[n]];
        for (n = 0; n < store.cursorKeys.length; n++)
            if (c[store.cursorKeys[n]] !== undefined)
                store[store.cursorProp(store.cursorKeys[n])] = c[store.cursorKeys[n]];
        store.rev++;
        store.queuePreview();
    }
    function resetInput() {
        var ii = store.defaults.input || {};
        for (var n = 0; n < store.inputKeys.length; n++)
            if (ii[store.inputKeys[n]] !== undefined)
                store[store.inputKeys[n]] = ii[store.inputKeys[n]];
        store.rev++;
        store.queuePreview();
    }

    Process { id: previewProc }
    Process { id: saveProc }
    Process { id: restoreProc }

    Process {
        id: defProc
        command: [Directories.rainBin, "hub", "hypr", "defaults"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { store.defaults = JSON.parse(this.text); } catch (e) {}
            }
        }
    }

    Process {
        id: getProc
        command: [Directories.rainBin, "hub", "hypr", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var o = JSON.parse(this.text);
                    store.adopt(o);
                    store.committed = JSON.parse(JSON.stringify(store.snapshot()));
                    store.ready = true;
                } catch (e) {
                    console.log("hub: hypr get parse failed: " + e);
                }
            }
        }
    }
}
