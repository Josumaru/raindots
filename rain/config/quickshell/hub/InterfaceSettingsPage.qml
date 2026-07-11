pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

Item {
    id: page

    function setConfig(k, v) {
        Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", k, String(v)]);
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.bottomMargin: 18
        contentWidth: width
        contentHeight: Math.max(col.height, height)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: sb; policy: ScrollBar.AsNeeded; width: 7
            contentItem: Rectangle {
                implicitWidth: 4; radius: Theme.radius; color: Theme.line
                opacity: sb.pressed ? 0.9 : (sb.hovered ? 0.7 : 0.4)
                Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            }
        }

        Column {
            id: col
            width: flick.width - 12
            spacing: 30

            SettingSection {
                width: parent.width; title: "DOCK"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable dock"
                    checked: false
                    onToggled: (v) => page.setConfig("dock.enable", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Hover to reveal"
                    checked: false
                    onToggled: (v) => page.setConfig("dock.hoverToReveal", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Pinned on startup"
                    checked: false
                    onToggled: (v) => page.setConfig("dock.pinnedOnStartup", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Tint app icons"
                    checked: false
                    onToggled: (v) => page.setConfig("dock.monochromeIcons", v)
                }
            }

            SettingSection {
                width: parent.width; title: "LOCK SCREEN"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Use Hyprlock"
                    checked: false
                    onToggled: (v) => page.setConfig("lockscreen.useHyprlock", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Background type"
                    options: [
                        { key: "0", label: "Wallpaper" },
                        { key: "1", label: "Solid color" },
                        { key: "2", label: "Blurred wallpaper" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("lockscreen.backgroundType", k)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Blur radius"; unit: "px"
                    from: 0; to: 50; step: 2; value: 10
                    onModified: (v) => page.setConfig("lockscreen.blurRadius", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Blur passes"
                    from: 1; to: 10; step: 1; value: 3
                    onModified: (v) => page.setConfig("lockscreen.blurPasses", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Use greetd"
                    checked: false
                    onToggled: (v) => page.setConfig("lockscreen.useGreetd", v)
                }
            }

            SettingSection {
                width: parent.width; title: "NOTIFICATIONS"

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Style"
                    options: [
                        { key: "0", label: "Minimal" },
                        { key: "1", label: "Full" }
                    ]
                    current: "0"
                    onChosen: (k) => page.setConfig("notifications.style", k)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show notification count"
                    checked: false
                    onToggled: (v) => page.setConfig("notifications.indicator.showCount", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Popup duration"; unit: "ms"
                    from: 1000; to: 30000; step: 500; value: 5000
                    onModified: (v) => page.setConfig("notifications.popupDuration", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Max notifications"
                    from: 1; to: 20; step: 1; value: 5
                    onModified: (v) => page.setConfig("notifications.maxNotifications", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Max per app"
                    from: 1; to: 10; step: 1; value: 3
                    onModified: (v) => page.setConfig("notifications.maxNotificationsPerApp", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show progress bars"
                    checked: false
                    onToggled: (v) => page.setConfig("notifications.showProgress", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show images"
                    checked: false
                    onToggled: (v) => page.setConfig("notifications.showImage", v)
                }
            }

            SettingSection {
                width: parent.width; title: "ANIMATIONS"

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Speed"
                    options: [
                        { key: "0.5", label: "Slow" },
                        { key: "1", label: "Normal" },
                        { key: "1.5", label: "Fast" },
                        { key: "2", label: "Very Fast" }
                    ]
                    current: "1"
                    onChosen: (k) => page.setConfig("animation.multiplier", k)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Reduced motion"
                    checked: false
                    onToggled: (v) => page.setConfig("animation.reducedMotion", v)
                }
            }

            SettingSection {
                width: parent.width; title: "CHEAT SHEET"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "macOS mod symbols"
                    checked: false
                    onToggled: (v) => page.setConfig("cheatsheet.useMacSymbol", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Function key symbols"
                    checked: false
                    onToggled: (v) => page.setConfig("cheatsheet.useFnSymbol", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Mouse symbols"
                    checked: false
                    onToggled: (v) => page.setConfig("cheatsheet.useMouseSymbol", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Split buttons"
                    checked: false
                    onToggled: (v) => page.setConfig("cheatsheet.splitButtons", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Key font size"; unit: "px"
                    from: 8; to: 30; step: 1; value: 14
                    onModified: (v) => page.setConfig("cheatsheet.fontSize.key", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Description font size"; unit: "px"
                    from: 8; to: 30; step: 1; value: 12
                    onModified: (v) => page.setConfig("cheatsheet.fontSize.comment", v)
                }
            }

            SettingSection {
                width: parent.width; title: "MOUSE & TOUCHPAD"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Natural scrolling"
                    checked: false
                    onToggled: (v) => page.setConfig("mouse.naturalScroll", v)
                }

                SliderRow {
                    width: Math.min(parent.width, 460); label: "Pointer speed"
                    from: -1; to: 1; step: 0.1; decimals: 1; value: 0
                    onModified: (v) => {
                        page.setConfig("mouse.sensitivity", Math.abs(v));
                        page.setConfig("mouse.accelProfile", v >= 0 ? "adaptive" : "flat");
                    }
                }
            }

            SettingSection {
                width: parent.width; title: "KEYBOARD"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Numlock on startup"
                    checked: false
                    onToggled: (v) => page.setConfig("keyboard.numlockOnStartup", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Repeat rate"; unit: "/s"
                    from: 15; to: 100; step: 5; value: 25
                    onModified: (v) => page.setConfig("keyboard.repeatRate", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Repeat delay"; unit: "ms"
                    from: 100; to: 1000; step: 50; value: 600
                    onModified: (v) => page.setConfig("keyboard.repeatDelay", v)
                }
            }
        }
    }
}
