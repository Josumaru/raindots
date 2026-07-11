import QtQuick
import QtQuick.Controls
import "Singletons"

// shortcut legend, read live from the rain CLI.
Flickable {
    id: page

    property var categories: []

    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        id: sb
        policy: ScrollBar.AsNeeded
        width: 7
        contentItem: Rectangle {
            implicitWidth: 4
            radius: Theme.radius
            color: Theme.line
            opacity: sb.pressed ? 0.9 : (sb.hovered ? 0.7 : 0.4)
            Behavior on opacity { NumberAnimation { duration: Theme.quick } }
        }
    }

    Column {
        id: col
        width: page.width - 10
        spacing: 30
        topPadding: 6
        bottomPadding: 18

        Repeater {
            model: page.categories
            delegate: KeybindGroup {
                width: col.width
                name: modelData.name
                binds: modelData.binds
            }
        }
    }
}
