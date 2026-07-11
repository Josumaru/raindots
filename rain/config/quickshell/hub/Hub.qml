pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "Singletons"

// Ryoku Settings: nav rail + content area. data + persisted state come
// from the rain CLI backend. most sections edit the live Hyprland config.
Rectangle {
    id: hub

    implicitWidth: 1360
    implicitHeight: 880

    property string section: "shell"
    property var keybindsModel: []
    readonly property bool searching: navRail.query.length > 0

    readonly property var sectionDefs: [
        { "key": "profile",         "name": "Profile",         "icon": "user",     "pinned": "top" },
        { "key": "quicksettings",   "name": "Quick",           "icon": "sparkles", "pinned": "top" },
        { "key": "displays",        "name": "Displays",        "icon": "display",  "group": "System" },
        { "key": "input",           "name": "Input",           "icon": "mouse",    "group": "System" },
        { "key": "keybinds",        "name": "Keybinds",        "icon": "keyboard", "group": "System" },
        { "key": "generalsettings", "name": "General",         "icon": "gear",     "group": "System" },
        { "key": "updates",         "name": "Updates",         "icon": "download", "pinned": "bottom" },
        { "key": "about",           "name": "About",           "icon": "star",     "pinned": "bottom" },
        { "key": "credits",         "name": "Credits",         "icon": "heart",    "pinned": "bottom" },
        { "key": "appearance",      "name": "Appearance",      "icon": "palette",  "group": "Desktop" },
        { "key": "shell",           "name": "Shell",           "icon": "gear",     "group": "Desktop" },
        { "key": "barsettings",     "name": "Bar",             "icon": "display",  "group": "Desktop" },
        { "key": "interfacesettings","name": "Interface",      "icon": "widgets",  "group": "Desktop" },
        { "key": "backgroundsettings","name": "Background",    "icon": "wallpaper","group": "Desktop" },
        { "key": "servicessettings", "name": "Services",       "icon": "chip",     "group": "Services" },
        { "key": "autostart",       "name": "Autostart",       "icon": "rocket",   "group": "Advanced" },
        { "key": "advancedsettings", "name": "Advanced",       "icon": "wrench",   "group": "Advanced" }
    ]

    readonly property var pageMeta: ({
        "profile":          { "title": "Profile", "subtitle": "Your machine as a collector's specimen." },
        "quicksettings":    { "title": "Quick Settings", "subtitle": "Language, bar, wallpaper, and first-time config." },
        "displays":         { "title": "Displays", "subtitle": "Detect and arrange your monitors." },
        "appearance":       { "title": "Appearance", "subtitle": "Window look: gaps, rounding, borders, blur, themes." },
        "input":            { "title": "Input", "subtitle": "Keyboard layout, pointer feel, touchpad behaviour." },
        "keybinds":         { "title": "Keybinds", "subtitle": "Every shortcut in the desktop." },
        "shell":            { "title": "Shell", "subtitle": "Bar, notifications, and the desktop visualiser." },
        "barsettings":      { "title": "Bar", "subtitle": "Position, style, and the modules your bar carries." },
        "interfacesettings":{ "title": "Interface", "subtitle": "Controls, animations, fonts, and the way the shell feels." },
        "backgroundsettings":{"title": "Background", "subtitle": "Wallpaper, colour generation, and transparency." },
        "servicessettings": { "title": "Services", "subtitle": "Background services, notifications, and daemons." },
        "advancedsettings": { "title": "Advanced", "subtitle": "Power user settings: debug and development." },
        "generalsettings":  { "title": "General", "subtitle": "Window rules, virtual desktops, and global behaviour." },
        "autostart":        { "title": "Autostart", "subtitle": "Commands that run when the session starts." },
        "about":            { "title": "About", "subtitle": "Version, credits, and the people behind raindots." },
        "updates":          { "title": "Updates", "subtitle": "Updates pending for your system." },
        "credits":          { "title": "Credits", "subtitle": "The projects and people this desktop is built on." }
    })

    function known(s) {
        for (var i = 0; i < hub.sectionDefs.length; i++)
            if (hub.sectionDefs[i].key === s) return true;
        return false;
    }

    function groupFor(s) {
        for (var i = 0; i < hub.sectionDefs.length; i++)
            if (hub.sectionDefs[i].key === s)
                return hub.sectionDefs[i].group || "Settings";
        return "Settings";
    }

    gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bgTop }
        GradientStop { position: 1.0; color: Theme.bgBot }
    }

    focus: true
    Keys.onEscapePressed: Qt.quit()
    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_K && (e.modifiers & Qt.ControlModifier)) {
            navRail.focusSearch();
            e.accepted = true;
        }
    }

    function configPathsFor(s) {
        var base = Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config");
        var hypr = base + "/hypr";
        var ryoku = base + "/ryoku";
        switch (s) {
        case "shell":       return [ryoku + "/shell.json"];
        case "autostart":   return [hypr + "/custom/execs.lua", hypr + "/custom/keybinds.lua"];
        default:            return [];
        }
    }

    function go(s) {
        navRail.query = "";
        if (hub.section === s) return;
        hub.section = s;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        NavRail {
            id: navRail
            Layout.preferredWidth: 252
            Layout.fillHeight: true
            sections: hub.sectionDefs
            current: hub.section
            onNavigate: (s) => hub.go(s)
            onEscaped: Qt.quit()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            PageHeader {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 40
                anchors.rightMargin: 64
                anchors.topMargin: 16
                eyebrow: hub.searching ? "Search" : hub.groupFor(hub.section)
                title: hub.searching ? "Search" : hub.pageMeta[hub.section].title
                subtitle: hub.searching ? "Results across every section" : hub.pageMeta[hub.section].subtitle
                configPaths: hub.searching ? [] : hub.configPathsFor(hub.section)
            }

            Loader {
                id: pageLoader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: 40
                anchors.rightMargin: 30
                anchors.topMargin: 14
                anchors.bottomMargin: 12

                sourceComponent: hub.searching ? searchComp : hub.pageFor(hub.section)

                onLoaded: {
                    if (!item) return;
                    item.opacity = 0;
                    item.y = 10;
                    fadeAnim.target = item;
                    slideAnim.target = item;
                    fadeAnim.restart();
                    slideAnim.restart();
                }
            }

            NumberAnimation {
                id: fadeAnim
                property: "opacity"
                to: 1
                duration: Theme.medium
                easing.type: Theme.ease
            }
            NumberAnimation {
                id: slideAnim
                property: "y"
                to: 0
                duration: Theme.medium
                easing.type: Theme.ease
            }
        }
    }

    function pageFor(s) {
        switch (s) {
        case "profile":          return profileComp;
        case "quicksettings":    return quickSettingsComp;
        case "appearance":       return appearanceComp;
        case "displays":         return displaysComp;
        case "keybinds":         return keybindsComp;
        case "input":            return inputComp;
        case "autostart":        return autostartComp;
        case "updates":          return updatesComp;
        case "credits":          return creditsComp;
        case "generalsettings":  return generalSettingsComp;
        case "barsettings":      return barSettingsComp;
        case "interfacesettings":return interfaceSettingsComp;
        case "backgroundsettings":return backgroundSettingsComp;
        case "servicessettings": return servicesSettingsComp;
        case "advancedsettings": return advancedSettingsComp;
        case "about":            return aboutComp;
        default:                 return shellComp;
        }
    }

    Component { id: searchComp; SearchResults { sections: hub.sectionDefs; categories: hub.keybindsModel; query: navRail.query; onNavigate: (s) => hub.go(s) } }
    Component { id: profileComp; ProfilePage {} }
    Component { id: quickSettingsComp; QuickSettingsPage {} }
    Component { id: appearanceComp; AppearancePage {} }
    Component { id: shellComp; ShellSettingsPage {} }
    Component { id: displaysComp; DisplaysPage {} }
    Component { id: keybindsComp; KeybindsPage { categories: hub.keybindsModel } }
    Component { id: inputComp; InputPage {} }
    Component { id: autostartComp; AutostartPage {} }
    Component { id: updatesComp; UpdatesPage {} }
    Component { id: creditsComp; CreditsPage {} }
    Component { id: generalSettingsComp; GeneralSettingsPage {} }
    Component { id: barSettingsComp; BarSettingsPage {} }
    Component { id: interfaceSettingsComp; InterfaceSettingsPage {} }
    Component { id: backgroundSettingsComp; BackgroundSettingsPage {} }
    Component { id: servicesSettingsComp; ServicesSettingsPage {} }
    Component { id: advancedSettingsComp; AdvancedSettingsPage {} }
    Component { id: aboutComp; AboutPage {} }

    // load keybinds model from backend on startup
    Process {
        id: keybindsProc
        command: [Directories.rainBin, "hub", "hypr", "keybinds"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    hub.keybindsModel = JSON.parse(this.text);
                } catch (e) {
                    console.log("hub: keybinds parse failed: " + e);
                }
            }
        }
    }

    Item {
        id: closeBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 22
        width: 26
        height: 26

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: closeHover.hovered ? Theme.ember : Theme.faint
            font.family: Theme.font
            font.pixelSize: 16
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }

        HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Qt.quit() }
    }
}
