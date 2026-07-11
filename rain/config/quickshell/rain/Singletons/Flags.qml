pragma Singleton
import QtQuick

// global toggle flags: do-not-disturb, keep-awake, game mode.
QtObject {
    property bool dnd: false
    property bool keepAwake: false
    property bool gameMode: false
}
