import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    SettingSection {
        width: parent.width
        title: Translation.tr("AI")

        MaterialTextArea {
            width: parent.width
            implicitHeight: 80
            placeholderText: Translation.tr("System prompt")
            text: Config.options.ai.systemPrompt
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Qt.callLater(() => {
                    Config.options.ai.systemPrompt = text;
                });
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("MUSIC RECOGNITION")

        NumberField {
            width: parent.width
            label: Translation.tr("Total duration timeout (s)")
            value: Config.options.musicRecognition.timeout
            from: 10; to: 100; step: 2
            onModified: (v) => Config.options.musicRecognition.timeout = v
        }

        NumberField {
            width: parent.width
            label: Translation.tr("Polling interval (s)")
            value: Config.options.musicRecognition.interval
            from: 2; to: 10; step: 1
            onModified: (v) => Config.options.musicRecognition.interval = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("NETWORKING")

        MaterialTextArea {
            width: parent.width
            implicitHeight: 60
            placeholderText: Translation.tr("User agent (for services that require it)")
            text: Config.options.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.networking.userAgent = text;
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("RESOURCES")

        NumberField {
            width: parent.width
            label: Translation.tr("Polling interval (ms)")
            value: Config.options.resources.updateInterval
            from: 100; to: 10000; step: 100
            onModified: (v) => Config.options.resources.updateInterval = v
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("SAVE PATHS")

        MaterialTextArea {
            width: parent.width
            implicitHeight: 50
            placeholderText: Translation.tr("Video Recording Path")
            text: Config.options.screenRecord.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenRecord.savePath = text;
            }
        }

        MaterialTextArea {
            width: parent.width
            implicitHeight: 50
            placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
            text: Config.options.screenSnip.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenSnip.savePath = text;
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("SEARCH")

        ToggleRow {
            width: parent.width
            label: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
            checked: Config.options.search.sloppy
            onToggled: (v) => Config.options.search.sloppy = v
        }

        MaterialTextArea {
            width: parent.width
            implicitHeight: 50
            placeholderText: Translation.tr("Action prefix")
            text: Config.options.search.prefix.action
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.search.prefix.action = text;
            }
        }

        MaterialTextArea {
            width: parent.width
            implicitHeight: 50
            placeholderText: Translation.tr("Clipboard prefix")
            text: Config.options.search.prefix.clipboard
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.search.prefix.clipboard = text;
            }
        }

        MaterialTextArea {
            width: parent.width
            implicitHeight: 50
            placeholderText: Translation.tr("Emoji prefix")
            text: Config.options.search.prefix.emoji
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.search.prefix.emoji = text;
            }
        }

        MaterialTextArea {
            width: parent.width
            implicitHeight: 50
            placeholderText: Translation.tr("Calculator prefix")
            text: Config.options.search.prefix.calc
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.search.prefix.calc = text;
            }
        }
    }
}
