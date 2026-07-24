import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    readonly property string pickerPath: Quickshell.shellPath("modules/ii/wallpaperPicker/Main.qml")

    function toggle() {
        Quickshell.execDetached(["bash", "-c",
            `qs -p "${root.pickerPath}"`
        ]);
    }

    IpcHandler {
        target: "wallpaperPicker"
        function toggle(): void {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "wallpaperPickerToggle"
        description: "Toggle wallpaper picker"
        onPressed: {
            root.toggle();
        }
    }
}