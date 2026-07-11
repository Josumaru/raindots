pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// notification state: unread count, popup list, dnd flag.
QtObject {
    id: notifs

    readonly property int unread: 0
    readonly property var popups: []
    readonly property bool dnd: false
}
