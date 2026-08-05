pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

Item {
    id: page

    // Visualizer (equalizer) live state
    property bool visualizerEnable: false
    property string visualizerPosition: "bottom"
    property string visualizerOrientation: "horizontal"
    property string visualizerDirection: "up"
    property real visualizerOffset: 0
    property real visualizerBarWidth: 6
    property real visualizerBarSpacing: 10
    property real visualizerMaxBarHeight: 200
    property real visualizerSmoothing: 150

    function setConfig(k, v) {
        Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", k, String(v)]);
    }

    Process {
        id: vizStateProc
        running: true
        command: ["cat", Directories.xdgConfig + "/rain/config.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const doc = JSON.parse(this.text);
                    const viz = doc.background?.widgets?.visualizer;
                    page.visualizerEnable = !!viz?.enable;
                    if (viz?.position) page.visualizerPosition = viz.position;
                    if (viz?.orientation) page.visualizerOrientation = viz.orientation;
                    if (viz?.direction) page.visualizerDirection = viz.direction;
                    if (viz?.offset !== undefined) page.visualizerOffset = viz.offset;
                    if (viz?.barWidth) page.visualizerBarWidth = viz.barWidth;
                    if (viz?.barSpacing) page.visualizerBarSpacing = viz.barSpacing;
                    if (viz?.maxBarHeight) page.visualizerMaxBarHeight = viz.maxBarHeight;
                    if (viz?.smoothingDuration) page.visualizerSmoothing = viz.smoothingDuration;
                } catch (e) { /* config may not exist yet */ }
            }
        }
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
                width: parent.width; title: "PARALLAX"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Vertical parallax"
                    checked: false
                    onToggled: (v) => page.setConfig("background.parallax.vertical", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Depends on workspace"
                    checked: false
                    onToggled: (v) => page.setConfig("background.parallax.enableWorkspace", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Depends on sidebars"
                    checked: false
                    onToggled: (v) => page.setConfig("background.parallax.enableSidebar", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Wallpaper zoom"; unit: "%"
                    from: 10; to: 200; step: 1; value: 100
                    onModified: (v) => page.setConfig("background.parallax.workspaceZoom", v / 100)
                }
            }

            SettingSection {
                width: parent.width; title: "WIDGET: CLOCK"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable clock widget"
                    checked: false
                    onToggled: (v) => page.setConfig("background.widgets.clock.enable", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Placement"
                    options: [
                        { key: "free", label: "Draggable" },
                        { key: "leastBusy", label: "Least busy" },
                        { key: "mostBusy", label: "Most busy" }
                    ]
                    current: "free"
                    onChosen: (k) => page.setConfig("background.widgets.clock.placementStrategy", k)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show only when locked"
                    checked: false
                    onToggled: (v) => page.setConfig("background.widgets.clock.showOnlyWhenLocked", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Clock style"
                    options: [
                        { key: "digital", label: "Digital" },
                        { key: "cookie", label: "Cookie" }
                    ]
                    current: "digital"
                    onChosen: (k) => page.setConfig("background.widgets.clock.style", k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Clock style (locked)"
                    options: [
                        { key: "digital", label: "Digital" },
                        { key: "cookie", label: "Cookie" }
                    ]
                    current: "digital"
                    onChosen: (k) => page.setConfig("background.widgets.clock.styleLocked", k)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Show tick marks"
                    checked: false
                    onToggled: (v) => page.setConfig("background.widgets.clock.showTicks", v)
                }

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Force analog"
                    checked: false
                    onToggled: (v) => page.setConfig("background.widgets.clock.forceAnalog", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Padding"; unit: "px"
                    from: 0; to: 100; step: 2; value: 20
                    onModified: (v) => page.setConfig("background.widgets.clock.padding", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Face style"
                    options: [
                        { key: "mono", label: "Monochrome" },
                        { key: "accent", label: "Accent" }
                    ]
                    current: "accent"
                    onChosen: (k) => page.setConfig("background.widgets.clock.faceStyle", k)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Font variant"
                    options: [
                        { key: "default", label: "Default" },
                        { key: "numbers", label: "Numbers" },
                        { key: "title", label: "Title" }
                    ]
                    current: "default"
                    onChosen: (k) => page.setConfig("background.widgets.clock.clockFont", k)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Custom font size"; unit: "px"
                    from: 12; to: 200; step: 4; value: 48
                    onModified: (v) => page.setConfig("background.widgets.clock.clockFontSize", v)
                }
            }

            SettingSection {
                width: parent.width; title: "WIDGET: WEATHER"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable weather widget"
                    checked: false
                    onToggled: (v) => page.setConfig("background.widgets.weather.enable", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Update interval"; unit: "min"
                    from: 5; to: 120; step: 5; value: 30
                    onModified: (v) => page.setConfig("background.widgets.weather.updateInterval", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Placement"
                    options: [
                        { key: "free", label: "Draggable" },
                        { key: "leastBusy", label: "Least busy" },
                        { key: "mostBusy", label: "Most busy" }
                    ]
                    current: "free"
                    onChosen: (k) => page.setConfig("background.widgets.weather.placementStrategy", k)
                }
            }

            SettingSection {
                width: parent.width; title: "WIDGET: NOTES"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable notes widget"
                    checked: false
                    onToggled: (v) => page.setConfig("background.widgets.notes.enable", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Placement"
                    options: [
                        { key: "free", label: "Draggable" },
                        { key: "leastBusy", label: "Least busy" },
                        { key: "mostBusy", label: "Most busy" }
                    ]
                    current: "free"
                    onChosen: (k) => page.setConfig("background.widgets.notes.placementStrategy", k)
                }
            }

            SettingSection {
                width: parent.width; title: "WIDGET: DEVICES"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable devices widget"
                    checked: false
                    onToggled: (v) => page.setConfig("background.widgets.devices.enable", v)
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Placement"
                    options: [
                        { key: "free", label: "Draggable" },
                        { key: "leastBusy", label: "Least busy" },
                        { key: "mostBusy", label: "Most busy" }
                    ]
                    current: "free"
                    onChosen: (k) => page.setConfig("background.widgets.devices.placementStrategy", k)
                }
            }

            SettingSection {
                width: parent.width; title: "WIDGET: VISUALIZER (EQ)"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Enable equalizer"
                    checked: page.visualizerEnable
                    onToggled: (v) => {
                        page.visualizerEnable = v;
                        page.setConfig("background.widgets.visualizer.enable", v)
                    }
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Position"
                    options: [
                        { key: "bottom", label: "Bottom" },
                        { key: "top", label: "Top" },
                        { key: "left", label: "Left" },
                        { key: "right", label: "Right" }
                    ]
                    current: page.visualizerPosition
                    onChosen: (k) => {
                        page.visualizerPosition = k;
                        page.setConfig("background.widgets.visualizer.position", k)
                    }
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Orientation"
                    options: [
                        { key: "horizontal", label: "Horizontal" },
                        { key: "vertical", label: "Vertical" }
                    ]
                    current: page.visualizerOrientation
                    onChosen: (k) => {
                        page.visualizerOrientation = k;
                        page.setConfig("background.widgets.visualizer.orientation", k)
                    }
                }

                ChoiceRow {
                    width: Math.min(parent.width, 460); label: "Direction"
                    options: [
                        { key: "up", label: "Up" },
                        { key: "down", label: "Down" },
                        { key: "right", label: "Right" },
                        { key: "left", label: "Left" }
                    ]
                    current: page.visualizerDirection
                    onChosen: (k) => {
                        page.visualizerDirection = k;
                        page.setConfig("background.widgets.visualizer.direction", k)
                    }
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Edge offset"; unit: "px"
                    from: 0; to: 200; step: 2; value: page.visualizerOffset
                    onModified: (v) => {
                        page.visualizerOffset = v;
                        page.setConfig("background.widgets.visualizer.offset", v)
                    }
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Bar width"; unit: "px"
                    from: 2; to: 24; step: 1; value: page.visualizerBarWidth
                    onModified: (v) => {
                        page.visualizerBarWidth = v;
                        page.setConfig("background.widgets.visualizer.barWidth", v)
                    }
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Bar spacing"; unit: "px"
                    from: 0; to: 40; step: 1; value: page.visualizerBarSpacing
                    onModified: (v) => {
                        page.visualizerBarSpacing = v;
                        page.setConfig("background.widgets.visualizer.barSpacing", v)
                    }
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Max bar height"; unit: "px"
                    from: 40; to: 500; step: 5; value: page.visualizerMaxBarHeight
                    onModified: (v) => {
                        page.visualizerMaxBarHeight = v;
                        page.setConfig("background.widgets.visualizer.maxBarHeight", v)
                    }
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Animation speed"; unit: "ms"
                    from: 30; to: 400; step: 10; value: page.visualizerSmoothing
                    onModified: (v) => {
                        page.visualizerSmoothing = v;
                        page.setConfig("background.widgets.visualizer.smoothingDuration", v)
                    }
                }
            }
        }
    }
}
