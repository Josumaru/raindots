pragma Singleton
import QtQuick

// lightweight cross-component event bus.
QtObject {
    signal signalled(string name)
    function signal(name) { signalled(name); }
}
