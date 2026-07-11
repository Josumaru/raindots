import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Singletons"

// side navigation rail with search, section groups with expand/collapse,
// pinned items at top and bottom, Icon.qml for all glyphs.
Rectangle {
    id: rail

    property var sections: []
    property string current: ""
    property string query: ""

    signal navigate(string section)
    signal escaped()

    // Derived groups from sections array
    readonly property var groups: {
        var g = {};
        var out = [];
        for (var i = 0; i < sections.length; i++) {
            var s = sections[i];
            if (s.pinned) continue;
            var grp = s.group || "Settings";
            if (!g[grp]) { g[grp] = []; out.push({ name: grp, items: g[grp] }); }
            g[grp].push(s);
        }
        return out;
    }

    readonly property var pinnedTop: {
        var out = [];
        for (var i = 0; i < sections.length; i++)
            if (sections[i].pinned === "top") out.push(sections[i]);
        return out;
    }

    readonly property var pinnedBottom: {
        var out = [];
        for (var i = 0; i < sections.length; i++)
            if (sections[i].pinned === "bottom") out.push(sections[i]);
        return out;
    }

    // which groups are expanded. the group holding the current section opens
    // automatically.
    property var expandedGroups: ({})
    readonly property string currentGroup: {
        for (var i = 0; i < groups.length; i++)
            for (var j = 0; j < groups[i].items.length; j++)
                if (groups[i].items[j].key === current)
                    return groups[i].name;
        return "";
    }

    function toggleGroup(name) {
        var e = Object.assign({}, rail.expandedGroups);
        e[name] = !e[name];
        rail.expandedGroups = e;
    }

    function focusSearch() { searchField.forceActiveFocus(); }

    color: Theme.rail

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // brand masthead
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "raindots"
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "力"
                color: Qt.rgba(Theme.brand.r, Theme.brand.g, Theme.brand.b, 0.25)
                font.family: Theme.fontJp
                font.pixelSize: 20
                font.weight: Font.Black
            }
        }

        // search field
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            height: 36
            radius: Theme.radius
            color: searchActive.containsMouse || searchField.activeFocus ? Theme.keyTop : "transparent"
            border.width: 1
            border.color: searchField.activeFocus ? Theme.ember : Theme.line
            Behavior on color { ColorAnimation { duration: Theme.quick } }
            Behavior on border.color { ColorAnimation { duration: Theme.quick } }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                text: "⌕"; color: Theme.faint; font.pixelSize: 15
                visible: searchField.text.length === 0 && !searchField.activeFocus
            }

            TextInput {
                id: searchField
                anchors.left: parent.left; anchors.leftMargin: 30
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.bright; font.family: Theme.font; font.pixelSize: 13
                clip: true; selectByMouse: true

                onTextChanged: rail.query = text
                Keys.onEscapePressed: {
                    rail.query = "";
                    focus = false;
                    rail.escaped();
                }
            }

            MouseArea { id: searchActive; anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: searchField.forceActiveFocus() }
        }

        // pinned top band
        Column {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 1

            Repeater {
                model: rail.pinnedTop

                delegate: NavRow {
                    currentSection: rail.current
                    navigate: (s) => rail.navigate(s)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            height: 1
            color: Theme.line; opacity: 0.3
            Layout.topMargin: 4
            Layout.bottomMargin: 4
        }

        // scrolling groups
        Item { Layout.fillHeight: true; Layout.fillWidth: true; clip: true

            Flickable {
                anchors.fill: parent
                anchors.topMargin: 6
                anchors.bottomMargin: 6
                contentHeight: groupsCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: groupsCol
                    width: parent.width

                    Repeater {
                        model: rail.groups

                        delegate: Column {
                            required property var modelData
                            required property int index

                            readonly property bool isOpen: rail.expandedGroups[modelData.name] !== false
                                || rail.currentGroup === modelData.name

                            width: groupsCol.width
                            spacing: 1

                            // group header
                            Item {
                                width: parent.width
                                height: 30

                                Rectangle {
                                    anchors.left: parent.left; anchors.leftMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 4; height: 4; radius: 2
                                    color: Theme.brand; opacity: 0.5
                                }

                                Text {
                                    anchors.left: parent.left; anchors.leftMargin: 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name.toUpperCase()
                                    color: Theme.faint
                                    font.family: Theme.mono; font.pixelSize: 9
                                    font.weight: Font.DemiBold; font.letterSpacing: 2
                                }

                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: isOpen ? "–" : "+"
                                    color: Theme.dim
                                    font.family: Theme.mono; font.pixelSize: 12; font.weight: Font.Bold
                                }

                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: rail.toggleGroup(modelData.name) }
                            }

                            Repeater {
                                model: isOpen ? modelData.items : []
                                delegate: NavRow {
                                    currentSection: rail.current
                                    navigate: (s) => rail.navigate(s)
                                }
                            }
                        }
                    }
                }
            }
        }

        // pinned bottom band
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.line; opacity: 0.3
        }

        Column {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 1
            Layout.topMargin: 4

            Repeater {
                model: rail.pinnedBottom
                delegate: NavRow {
                    currentSection: rail.current
                    navigate: (s) => rail.navigate(s)
                }
            }
        }

        // footer
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
            Layout.topMargin: 6
            text: "raindots"
            color: Theme.faint
            font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1.5
        }
    }

}
