import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

import qs.modules.rain.sidebarRight.quickToggles.hybridStyle

AbstractQuickPanel {
    id: root

    Layout.fillWidth: true

    property bool editMode: false
    property real spacing: 6
    property real padding: 10
    property int columnCount: 6

    readonly property real cellSize: Math.max(30, Math.floor((root.width - padding * 2 - spacing * (columnCount - 1)) / columnCount))

    readonly property list<string> availableToggleTypes: ["network", "bluetooth", "idleInhibitor", "easyEffects", "nightLight", "darkMode", "cloudflareWarp", "gameMode", "screenSnip", "colorPicker", "onScreenKeyboard", "mic", "audio", "notifications", "powerProfile", "musicRecognition", "antiFlashbang"]
    readonly property list<var> toggles: Config.ready ? Config.options.sidebar.quickToggles.android.toggles : []
    readonly property list<var> toggleRows: toggleRowsForList(toggles)
    readonly property list<var> unusedToggles: {
        const types = availableToggleTypes.filter(type => !toggles.some(toggle => (toggle && toggle.type === type)))
        return types.map(type => { return { type: type, size: 1 } })
    }
    readonly property list<var> unusedToggleRows: toggleRowsForList(unusedToggles)

    readonly property QtObject networkModel: NetworkToggle {}
    readonly property QtObject bluetoothModel: BluetoothToggle {}
    readonly property QtObject idleInhibitorModel: IdleInhibitorToggle {}
    readonly property QtObject micModel: MicToggle {}
    readonly property QtObject audioModel: AudioToggle {}
    readonly property QtObject nightLightModel: NightLightToggle {}
    readonly property QtObject easyEffectsModel: EasyEffectsToggle {}
    readonly property QtObject cloudflareWarpModel: CloudflareWarpToggle {}
    readonly property QtObject darkModeModel: DarkModeToggle {}
    readonly property QtObject gameModeModel: GameModeToggle {}
    readonly property QtObject musicRecognitionModel: MusicRecognitionToggle {}
    readonly property QtObject screenSnipModel: ScreenSnipToggle {}
    readonly property QtObject colorPickerModel: ColorPickerToggle {}
    readonly property QtObject onScreenKeyboardModel: OnScreenKeyboardToggle {}
    readonly property QtObject notificationModel: NotificationToggle {}
    readonly property QtObject powerProfileModel: PowerProfilesToggle {}
    readonly property QtObject antiFlashbangModel: AntiFlashbangToggle {}

    function modelForType(t) {
        if (t === "network") return networkModel
        if (t === "bluetooth") return bluetoothModel
        if (t === "idleInhibitor") return idleInhibitorModel
        if (t === "mic") return micModel
        if (t === "audio") return audioModel
        if (t === "nightLight") return nightLightModel
        if (t === "easyEffects") return easyEffectsModel
        if (t === "cloudflareWarp") return cloudflareWarpModel
        if (t === "darkMode") return darkModeModel
        if (t === "gameMode") return gameModeModel
        if (t === "musicRecognition") return musicRecognitionModel
        if (t === "screenSnip") return screenSnipModel
        if (t === "colorPicker") return colorPickerModel
        if (t === "onScreenKeyboard") return onScreenKeyboardModel
        if (t === "notifications") return notificationModel
        if (t === "powerProfile") return powerProfileModel
        if (t === "antiFlashbang") return antiFlashbangModel
        return null
    }

    function toggleRowsForList(togglesList) {
        var rows = [];
        var row = [];
        var totalSize = 0;
        for (var i = 0; i < togglesList.length; i++) {
            if (!togglesList[i]) continue;
            if (totalSize + togglesList[i].size > columnCount) {
                rows.push(row);
                row = [];
                totalSize = 0;
            }
            row.push(togglesList[i]);
            totalSize += togglesList[i].size;
        }
        if (row.length > 0) {
            rows.push(row);
        }
        return rows;
    }

    implicitHeight: (editMode ? contentItem.implicitHeight : usedRows.implicitHeight) + padding * 2
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    Column {
        id: contentItem
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 12

        Column {
            id: usedRows
            spacing: root.spacing

            Repeater {
                id: usedRowsRepeater
                model: ScriptModel {
                    values: Array(root.toggleRows.length)
                }
                delegate: ButtonGroup {
                    id: toggleRow
                    required property int index
                    property var modelData: root.toggleRows[index]
                    property int startingIndex: {
                        const rows = root.toggleRows;
                        let sum = 0;
                        for (let i = 0; i < index; i++) {
                            sum += rows[i].length;
                        }
                        return sum;
                    }
                    spacing: root.spacing

                    Repeater {
                        model: ScriptModel {
                            values: toggleRow?.modelData ?? []
                        }
                        delegate: HybridToggleButton {
                            required property int index
                            required property var modelData
                            buttonIndex: toggleRow.startingIndex + index
                            buttonData: modelData
                            editMode: root.editMode
                            cellSize: root.cellSize
                            toggleType: modelData.type
                            toggleModel: root.modelForType(modelData.type)
                            onOpenMenu: {
                                const t = modelData.type
                                if (t === "network") root.openWifiDialog()
                                else if (t === "bluetooth") root.openBluetoothDialog()
                                else if (t === "mic") root.openAudioInputDialog()
                                else if (t === "audio") root.openAudioOutputDialog()
                                else if (t === "nightLight") root.openNightLightDialog()
                            }
                        }
                    }
                }
            }
        }

        FadeLoader {
            shown: root.editMode
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: root.cellSize / 2
                rightMargin: root.cellSize / 2
            }
            sourceComponent: Rectangle {
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }
        }

        FadeLoader {
            shown: root.editMode
            sourceComponent: Column {
                id: unusedRows
                spacing: root.spacing

                Repeater {
                    model: ScriptModel {
                        values: Array(root.unusedToggleRows.length)
                    }
                    delegate: ButtonGroup {
                        id: unusedToggleRow
                        required property int index
                        property var modelData: root.unusedToggleRows[index]
                        spacing: root.spacing

                        Repeater {
                            model: ScriptModel {
                                values: unusedToggleRow?.modelData ?? []
                            }
                            delegate: HybridToggleButton {
                                required property int index
                                required property var modelData
                                buttonIndex: -1
                                buttonData: modelData
                                editMode: root.editMode
                                cellSize: root.cellSize
                                toggleType: modelData.type
                                toggleModel: root.modelForType(modelData.type)
                            }
                        }
                    }
                }
            }
        }
    }
}
