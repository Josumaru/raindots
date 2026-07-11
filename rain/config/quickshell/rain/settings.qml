//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ApplicationWindow {
    id: root
    property string firstRunFilePath: CF.FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 8
    property bool showNextTime: false
    property var pages: [
        {
            name: Translation.tr("Quick"),
            icon: "instant_mix",
            subtitle: Translation.tr("First things: language, bar, wallpaper, and policies."),
            component: "modules/settings/QuickConfig.qml",
            group: Translation.tr("Start")
        },
        {
            name: Translation.tr("General"),
            icon: "browse",
            subtitle: Translation.tr("Window rules, virtual desktops, and global behaviour."),
            component: "modules/settings/GeneralConfig.qml",
            group: Translation.tr("System")
        },
        {
            name: Translation.tr("Bar"),
            icon: "toast",
            iconRotation: 180,
            subtitle: Translation.tr("Position, style, and the modules your bar carries."),
            component: "modules/settings/BarConfig.qml",
            group: Translation.tr("Interface")
        },
        {
            name: Translation.tr("Background"),
            icon: "texture",
            subtitle: Translation.tr("Wallpaper, colour generation, and transparency."),
            component: "modules/settings/BackgroundConfig.qml",
            group: Translation.tr("Interface")
        },
        {
            name: Translation.tr("Interface"),
            icon: "bottom_app_bar",
            subtitle: Translation.tr("Controls, animations, fonts, and the way the shell feels."),
            component: "modules/settings/InterfaceConfig.qml",
            group: Translation.tr("Interface")
        },
        {
            name: Translation.tr("Services"),
            icon: "settings",
            subtitle: Translation.tr("Background services, notifications, and daemons."),
            component: "modules/settings/ServicesConfig.qml",
            group: Translation.tr("System")
        },
        {
            name: Translation.tr("Advanced"),
            icon: "construction",
            subtitle: Translation.tr("Power user settings: debug, development, and dangerous levers."),
            component: "modules/settings/AdvancedConfig.qml",
            group: Translation.tr("System")
        },
        {
            name: Translation.tr("About"),
            icon: "info",
            subtitle: Translation.tr("Version, credits, and the people behind illogical-impulse."),
            component: "modules/settings/About.qml",
            group: Translation.tr("System")
        }
    ]
    property int currentPage: 0

    readonly property var groups: {
        var seen = ({});
        var out = [];
        for (var i = 0; i < root.pages.length; i++) {
            var g = root.pages[i].group;
            if (!seen[g]) { seen[g] = true; out.push(g); }
        }
        return out;
    }

    function groupOf(index) {
        return root.pages[index]?.group ?? "";
    }

    visible: true
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0
    }

    minimumWidth: 750
    minimumHeight: 500
    width: 1100
    height: 750

    color: Appearance.m3colors.m3background

    Row {
        anchors.fill: parent

        // ── sidebar ────────────────────────────────────────────────────────
        Rectangle {
            id: sidebar
            width: 252
            height: parent.height
            color: Appearance.warm.bgBase

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Appearance.warm.hairline
            }

            // brand masthead
            Item {
                id: masthead
                width: parent.width
                height: 96

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.warm.bgBase

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            StyledText {
                                text: "ILLOGICAL"
                                color: Appearance.warm.onSurface
                                font.pixelSize: 15
                                font.weight: Font.Black
                                font.letterSpacing: 3
                            }
                            StyledText {
                                text: "IMPULSE"
                                color: Appearance.warm.accent
                                font.pixelSize: 15
                                font.weight: Font.Black
                                font.letterSpacing: 3
                            }
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Translation.tr("settings")
                            color: Appearance.warm.onSurfaceDim
                            font.pixelSize: 9
                            font.family: Appearance.font.family.mono
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            // nav sections
            Flickable {
                id: navFlick
                anchors.top: masthead.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: 8
                clip: true
                contentHeight: navCol.height
                boundsBehavior: Flickable.StopAtBounds

                property real navItemH: 44
                property real groupHeaderH: 36

                function itemY(index) {
                    var y = 0;
                    var last = null;
                    for (var i = 0; i < root.pages.length; i++) {
                        if (root.pages[i].group !== last) {
                            y += navFlick.groupHeaderH;
                            last = root.pages[i].group;
                        }
                        if (i === index) return y;
                        y += navFlick.navItemH;
                    }
                    return 0;
                }

                Rectangle {
                    id: navSelector
                    x: 12
                    width: navFlick.width - 24
                    height: 42
                    y: navFlick.itemY(root.currentPage) + (navFlick.navItemH - height) / 2
                    color: Appearance.warm.bgSurfaceHigh
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutExpo } }
                }

                Column {
                    id: navCol
                    width: navFlick.width
                    spacing: 0

                    Repeater {
                        model: root.pages

                        delegate: Column {
                            id: row
                            required property int index
                            required property var modelData
                            readonly property bool firstOfGroup: row.index === 0 || root.pages[row.index - 1].group !== row.modelData.group
                            width: parent.width

                            // group header
                            Item {
                                width: parent.width
                                height: row.firstOfGroup ? navFlick.groupHeaderH : 0
                                visible: row.firstOfGroup

                                Rectangle {
                                    visible: row.index > 0
                                    anchors.top: parent.top
                                    anchors.topMargin: 8
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 24
                                    anchors.rightMargin: 18
                                    height: 1
                                    color: Appearance.warm.hairline
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 24
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 8
                                    spacing: 8

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 5
                                        height: 5
                                        color: Appearance.warm.accent
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: row.modelData.group
                                        color: Appearance.warm.onSurfaceDim
                                        font.pixelSize: 10
                                        font.family: Appearance.font.family.mono
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 2
                                    }
                                }
                            }

                            // nav item
                            Item {
                                width: parent.width
                                height: navFlick.navItemH

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentPage = row.index
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 14

                                    Icon {
                                        name: row.modelData.icon
                                        size: 18
                                        tint: root.currentPage === row.index ?
                                            Appearance.warm.accent :
                                            (navHover.containsMouse ? Appearance.warm.onSurface : Appearance.warm.onSurfaceDim)
                                        rotation: row.modelData.iconRotation || 0
                                        Behavior on tint {
                                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                        }
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: row.modelData.name
                                        font.pixelSize: 14
                                        font.weight: root.currentPage === row.index ? Font.DemiBold : Font.Medium
                                        color: root.currentPage === row.index ?
                                            Appearance.warm.onSurface :
                                            (navHover.containsMouse ? Appearance.warm.onSurface : Appearance.warm.onSurfaceDim)
                                        Behavior on color {
                                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                        }
                                    }
                                }

                                HoverHandler { id: navHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }

            // footer
            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 26
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                text: "ii  shell"
                color: Appearance.warm.onSurfaceDim
                opacity: 0.6
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: Appearance.font.family.mono
            }
        }

        // ── content area ────────────────────────────────────────────────────
        Item {
            width: parent.width - 252
            height: parent.height

            // page header
            Column {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 40
                anchors.rightMargin: 64
                anchors.topMargin: 16
                spacing: 10

                Row {
                    spacing: 10
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 1.5
                        color: Appearance.warm.accent
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.pages[root.currentPage]?.group ?? ""
                        color: Appearance.warm.onSurfaceDim
                        font.pixelSize: 10
                        font.family: Appearance.font.family.mono
                        font.weight: Font.DemiBold
                        font.letterSpacing: 3
                    }
                }

                StyledText {
                    id: pageTitle
                    text: root.pages[root.currentPage]?.name ?? ""
                    color: Appearance.warm.onSurface
                    font.pixelSize: 36
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.5
                }

                StyledText {
                    text: root.pages[root.currentPage]?.subtitle ?? ""
                    visible: text.length > 0
                    width: parent.width * 0.62
                    wrapMode: Text.WordWrap
                    color: Appearance.warm.onSurfaceDim
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    lineHeight: 1.35
                }
            }

            // page content container
            Rectangle {
                id: contentBg
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerCol.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: 36
                anchors.rightMargin: 30
                anchors.topMargin: 20
                anchors.bottomMargin: 12

                color: Appearance.warm.bgSurfaceLow
                clip: true

                Keys.onPressed: (event) => {
                    if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown) {
                            root.currentPage = Math.min(root.currentPage + 1, root.pages.length - 1)
                            event.accepted = true;
                        }
                        else if (event.key === Qt.Key_PageUp) {
                            root.currentPage = Math.max(root.currentPage - 1, 0)
                            event.accepted = true;
                        }
                        else if (event.key === Qt.Key_Tab) {
                            root.currentPage = (root.currentPage + 1) % root.pages.length;
                            event.accepted = true;
                        }
                        else if (event.key === Qt.Key_Backtab) {
                            root.currentPage = (root.currentPage - 1 + root.pages.length) % root.pages.length;
                            event.accepted = true;
                        }
                    }
                }

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: 20
                    opacity: 1.0
                    y: 0

                    active: Config.ready
                    Component.onCompleted: {
                        source = root.pages[0].component
                    }

                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            switchAnim.complete();
                            switchAnim.start();
                        }
                    }

                    SequentialAnimation {
                        id: switchAnim

                        ParallelAnimation {
                            NumberAnimation {
                                target: pageLoader
                                properties: "opacity"
                                to: 0
                                duration: 100
                                easing.type: Easing.OutExpo
                            }
                            NumberAnimation {
                                target: pageLoader
                                properties: "y"
                                to: 10
                                duration: 100
                                easing.type: Easing.OutExpo
                            }
                        }
                        PropertyAction {
                            target: pageLoader
                            property: "source"
                            value: root.pages[root.currentPage].component
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: pageLoader
                                properties: "opacity"
                                to: 1
                                duration: 240
                                easing.type: Easing.OutExpo
                            }
                            NumberAnimation {
                                target: pageLoader
                                properties: "y"
                                to: 0
                                duration: 240
                                easing.type: Easing.OutExpo
                            }
                        }
                    }
                }
            }
        }
    }

    // close button
    Item {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 22
        width: 26
        height: 26

        Icon {
            name: "close"
            size: 16
            tint: closeHover.containsMouse ? Appearance.warm.accent : Appearance.warm.onSurfaceDim
            Behavior on tint {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.close() }
    }
}
