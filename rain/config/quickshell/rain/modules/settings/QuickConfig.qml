import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    Process {
        id: randomWallProc
        property string status: ""
        property string scriptPath: `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`
        command: ["bash", "-c", FileUtils.trimFileProtocol(randomWallProc.scriptPath)]
        stdout: SplitParser {
            onRead: data => {
                randomWallProc.status = data.trim();
            }
        }
    }

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                Icon {
                    name: dark ? "dark_mode" : "light_mode"
                    size: 30
                    tint: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("WALLPAPER & COLORS")

        RowLayout {
            width: parent.width
            spacing: 16

            Item {
                implicitWidth: 340
                implicitHeight: 200
                visible: Config.options.background.wallpaperPath.length > 0

                StyledImage {
                    id: wallpaperPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 360
                            height: 200
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: Konachan")
                    onClicked: {
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_konachan_wall.sh`;
                        randomWallProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    visible: Config.options.policies.weeb === 1
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "ifl"
                    mainText: randomWallProc.running ? Translation.tr("Be patient...") : Translation.tr("Random: osu! seasonal")
                    onClicked: {
                        randomWallProc.scriptPath = `${Directories.scriptPath}/colors/random/random_osu_wall.sh`;
                        randomWallProc.running = true;
                    }
                    StyledToolTip {
                        text: Translation.tr("Random osu! seasonal background\nImage is saved to ~/Pictures/Wallpapers")
                    }
                }
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    StyledToolTip {
                        text: Translation.tr("Pick wallpaper image on your system")
                    }
                    onClicked: {
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
                    }
                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: Translation.tr("Choose file")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            RowLayout {
                                spacing: 3
                                KeyboardKey { key: "Ctrl" }
                                KeyboardKey { key: Config.options.cheatsheet.superKey ?? "󰖳" }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }
                                KeyboardKey { key: "T" }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    uniformCellSizes: true
                    SmallLightDarkPreferenceButton { Layout.fillHeight: true; dark: false }
                    SmallLightDarkPreferenceButton { Layout.fillHeight: true; dark: true }
                }
            }
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Palette")
            options: [
                { key: "auto", label: Translation.tr("Auto") },
                { key: "scheme-content", label: Translation.tr("Content") },
                { key: "scheme-expressive", label: Translation.tr("Expressive") },
                { key: "scheme-fidelity", label: Translation.tr("Fidelity") },
                { key: "scheme-fruit-salad", label: Translation.tr("Fruit Salad") },
                { key: "scheme-monochrome", label: Translation.tr("Monochrome") },
                { key: "scheme-neutral", label: Translation.tr("Neutral") },
                { key: "scheme-rainbow", label: Translation.tr("Rainbow") },
                { key: "scheme-tonal-spot", label: Translation.tr("Tonal Spot") }
            ]
            current: Config.options.appearance.palette.type
            onChosen: (k) => {
                Config.options.appearance.palette.type = k;
                Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
            }
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Transparency")
            checked: Config.options.appearance.transparency.enable
            onToggled: (v) => Config.options.appearance.transparency.enable = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("BAR & SCREEN")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Bar position")
            options: [
                { key: "0", label: Translation.tr("Top") },
                { key: "2", label: Translation.tr("Left") },
                { key: "1", label: Translation.tr("Bottom") },
                { key: "3", label: Translation.tr("Right") }
            ]
            current: String((Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0))
            onChosen: (k) => {
                var v = parseInt(k);
                Config.options.bar.bottom = (v & 1) !== 0;
                Config.options.bar.vertical = (v & 2) !== 0;
            }
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Bar style")
            options: [
                { key: "0", label: Translation.tr("Hug") },
                { key: "1", label: Translation.tr("Float") },
                { key: "2", label: Translation.tr("Rect") }
            ]
            current: String(Config.options.bar.cornerStyle)
            onChosen: (k) => Config.options.bar.cornerStyle = parseInt(k)
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Screen round corner")
            options: [
                { key: "0", label: Translation.tr("No") },
                { key: "1", label: Translation.tr("Yes") },
                { key: "2", label: Translation.tr("When not fullscreen") }
            ]
            current: String(Config.options.appearance.fakeScreenRounding)
            onChosen: (k) => Config.options.appearance.fakeScreenRounding = parseInt(k)
        }
    }

    Rectangle {
        width: parent.width
        height: 60
        color: Appearance?.warm.bgSurface ?? "transparent"
        border.width: 1
        border.color: Appearance.warm.hairline
        opacity: 0.6

        RowLayout {
            anchors.centerIn: parent
            spacing: 12

            Icon { name: "info"; size: 16; tint: Appearance.warm.onSurfaceDim }
            StyledText {
                text: Translation.tr('Not all options available here. See Config file in sidebar for more.')
                color: Appearance.warm.onSurfaceDim
                font.pixelSize: 12
            }
        }
    }
}
