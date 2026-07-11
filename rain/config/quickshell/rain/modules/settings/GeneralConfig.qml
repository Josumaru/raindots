import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("AUDIO")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onToggled: (v) => Config.options.audio.protection.enable = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Max allowed increase")
            value: Config.options.audio.protection.maxAllowedIncrease
            from: 0; to: 100; step: 2
            enabled: Config.options.audio.protection.enable
            onModified: (v) => Config.options.audio.protection.maxAllowedIncrease = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Volume limit")
            value: Config.options.audio.protection.maxAllowed
            from: 0; to: 154; step: 2
            enabled: Config.options.audio.protection.enable
            onModified: (v) => Config.options.audio.protection.maxAllowed = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("BATTERY")

        NumberField {
            width: parent.width
            label: Translation.tr("Low warning")
            value: Config.options.battery.low
            from: 0; to: 100; step: 5
            onModified: (v) => Config.options.battery.low = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Critical warning")
            value: Config.options.battery.critical
            from: 0; to: 100; step: 5
            onModified: (v) => Config.options.battery.critical = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Automatic suspend")
            checked: Config.options.battery.automaticSuspend
            onToggled: (v) => Config.options.battery.automaticSuspend = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Suspend at")
            value: Config.options.battery.suspend
            from: 0; to: 100; step: 5
            enabled: Config.options.battery.automaticSuspend
            onModified: (v) => Config.options.battery.suspend = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Full warning")
            value: Config.options.battery.full
            from: 0; to: 101; step: 5
            onModified: (v) => Config.options.battery.full = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("LANGUAGE")

        StyledComboBox {
            id: languageSelector
            width: parent.width
            buttonIcon: "language"
            textRole: "displayName"

            model: [
                { displayName: Translation.tr("Auto (System)"), value: "auto" },
                ...Translation.allAvailableLanguages.map(lang => {
                    return { displayName: lang, value: lang };
                })
            ]

            currentIndex: {
                const index = model.findIndex(item => item.value === Config.options.language.ui);
                return index !== -1 ? index : 0;
            }

            onActivated: index => {
                Config.options.language.ui = model[index].value;
            }
        }

        RowLayout {
            width: parent.width
            spacing: 8

            MaterialTextArea {
                id: localeInput
                Layout.fillWidth: true
                implicitHeight: 40
                placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
            }

            RippleButtonWithIcon {
                id: generateTranslationBtn
                Layout.fillHeight: true
                nerdIcon: "\u{f01b}"
                enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                onClicked: {
                    translationProc.locale = localeInput.text.trim();
                    translationProc.running = false;
                    translationProc.running = true;
                }
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("POLICIES")

        ChoiceRow {
            width: parent.width
            label: Translation.tr("AI")
            options: [
                { key: "0", label: Translation.tr("No") },
                { key: "1", label: Translation.tr("Yes") },
                { key: "2", label: Translation.tr("Local only") }
            ]
            current: String(Config.options.policies.ai)
            onChosen: (k) => Config.options.policies.ai = parseInt(k)
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Weeb")
            options: [
                { key: "0", label: Translation.tr("No") },
                { key: "1", label: Translation.tr("Yes") },
                { key: "2", label: Translation.tr("Closet") }
            ]
            current: String(Config.options.policies.weeb)
            onChosen: (k) => Config.options.policies.weeb = parseInt(k)
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("SOUNDS")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Battery sounds")
            checked: Config.options.sounds.battery
            onToggled: (v) => Config.options.sounds.battery = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Pomodoro sounds")
            checked: Config.options.sounds.pomodoro
            onToggled: (v) => Config.options.sounds.pomodoro = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("TIME")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onToggled: (v) => Config.options.time.secondPrecision = v
        }

        ChoiceRow {
            width: parent.width
            label: Translation.tr("Format")
            options: [
                { key: "hh:mm", label: Translation.tr("24h") },
                { key: "h:mm ap", label: Translation.tr("12h am/pm") },
                { key: "h:mm AP", label: Translation.tr("12h AM/PM") }
            ]
            current: Config.options.time.format
            onChosen: (k) => {
                if (k === "hh:mm") {
                    Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                } else {
                    Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                }
                Config.options.time.format = k;
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("WORK SAFETY")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Hide clipboard images from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onToggled: (v) => Config.options.workSafety.enable.clipboard = v
        }

        ToggleRow {
            width: parent.width
            label: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onToggled: (v) => Config.options.workSafety.enable.wallpaper = v
        }
    }
}
