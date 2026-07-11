pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

Item {
    id: page

    property string systemPrompt: ""
    property string userAgent: ""
    property string recordPath: ""
    property string snipPath: ""
    property string actionPrefix: ""
    property string clipboardPrefix: ""
    property string emojiPrefix: ""
    property string calcPrefix: ""

    function setConfig(k, v) {
        Quickshell.execDetached([Directories.rainBin, "hub", "config", "set", k, String(v)]);
    }

    Process {
        id: promptProc
        command: [Directories.rainBin, "hub", "config", "get", "ai.systemPrompt"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: page.systemPrompt = this.text.trim()
        }
    }
    Process {
        id: uaProc
        command: [Directories.rainBin, "hub", "config", "get", "networking.userAgent"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: page.userAgent = this.text.trim()
        }
    }
    Process {
        id: recProc
        command: [Directories.rainBin, "hub", "config", "get", "screenRecord.savePath"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: page.recordPath = this.text.trim()
        }
    }
    Process {
        id: snipProc
        command: [Directories.rainBin, "hub", "config", "get", "screenSnip.savePath"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: page.snipPath = this.text.trim()
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
                width: parent.width; title: "AI"

                Rectangle {
                    width: Math.min(parent.width, 460); height: 100
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: promptInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.systemPrompt
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        wrapMode: TextEdit.Wrap
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("ai.systemPrompt", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "System prompt for AI assistant"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }

                Row {
                    width: parent.width; spacing: 10
                    HubButton {
                        label: "Save prompt"; icon: "check"
                        onClicked: page.setConfig("ai.systemPrompt", promptInput.text)
                    }
                }
            }

            SettingSection {
                width: parent.width; title: "MUSIC RECOGNITION"

                NumberField {
                    width: Math.min(parent.width, 460); label: "Timeout"; unit: "s"
                    from: 10; to: 100; step: 2; value: 30
                    onModified: (v) => page.setConfig("musicRecognition.timeout", v)
                }

                NumberField {
                    width: Math.min(parent.width, 460); label: "Polling interval"; unit: "s"
                    from: 2; to: 10; step: 1; value: 4
                    onModified: (v) => page.setConfig("musicRecognition.interval", v)
                }
            }

            SettingSection {
                width: parent.width; title: "NETWORKING"

                Rectangle {
                    width: Math.min(parent.width, 460); height: 80
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: uaInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.userAgent
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("networking.userAgent", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "User agent for services"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }
            }

            SettingSection {
                width: parent.width; title: "RESOURCES"

                NumberField {
                    width: Math.min(parent.width, 460); label: "Polling interval"; unit: "ms"
                    from: 100; to: 10000; step: 100; value: 1000
                    onModified: (v) => page.setConfig("resources.updateInterval", v)
                }
            }

            SettingSection {
                width: parent.width; title: "SAVE PATHS"

                Rectangle {
                    width: Math.min(parent.width, 460); height: 60
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: recInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.recordPath
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("screenRecord.savePath", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Video recording path"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    width: Math.min(parent.width, 460); height: 60
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: snipInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.snipPath
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("screenSnip.savePath", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Screenshot path (empty = clipboard only)"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }
            }

            SettingSection {
                width: parent.width; title: "SEARCH"

                ToggleRow {
                    width: Math.min(parent.width, 460); label: "Levenshtein algorithm"
                    checked: false
                    onToggled: (v) => page.setConfig("search.sloppy", v)
                }

                Rectangle {
                    width: Math.min(parent.width, 460); height: 60
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: actInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.actionPrefix
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("search.prefix.action", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Action prefix"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    width: Math.min(parent.width, 460); height: 60
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: clipInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.clipboardPrefix
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("search.prefix.clipboard", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Clipboard prefix"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    width: Math.min(parent.width, 460); height: 60
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: emojiInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.emojiPrefix
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("search.prefix.emoji", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Emoji prefix"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    width: Math.min(parent.width, 460); height: 60
                    color: Theme.surfaceLo; border.width: 1; border.color: Theme.line

                    TextInput {
                        id: calcInput
                        anchors.fill: parent; anchors.margins: 12
                        text: page.calcPrefix
                        color: Theme.bright
                        font.family: Theme.font; font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onEditingFinished: page.setConfig("search.prefix.calc", text)
                        Text {
                            anchors.fill: parent
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Calculator prefix"
                            color: Theme.faint
                            font.family: Theme.font; font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
