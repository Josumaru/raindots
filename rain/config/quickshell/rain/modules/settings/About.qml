import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    SettingSection {
        width: parent.width
        title: Translation.tr("DISTRO")

        RowLayout {
            width: parent.width
            spacing: 20

            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath(SystemInfo.logo)
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                StyledText {
                    text: SystemInfo.distroName
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    text: SystemInfo.homeUrl
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 6

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: Qt.openUrlExternally(SystemInfo.documentationUrl)
            }
            RippleButtonWithIcon {
                materialIcon: "support"
                mainText: Translation.tr("Help & Support")
                onClicked: Qt.openUrlExternally(SystemInfo.supportUrl)
            }
            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Report a Bug")
                onClicked: Qt.openUrlExternally(SystemInfo.bugReportUrl)
            }
            RippleButtonWithIcon {
                materialIcon: "policy"
                materialIconFill: false
                mainText: Translation.tr("Privacy Policy")
                onClicked: Qt.openUrlExternally(SystemInfo.privacyPolicyUrl)
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("DOTFILES")

        RowLayout {
            width: parent.width
            spacing: 20

            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath("illogical-impulse")
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                StyledText {
                    text: Translation.tr("illogical-impulse")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    text: SystemInfo.documentationUrl
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 6

            RippleButtonWithIcon {
                materialIcon: "star"
                mainText: Translation.tr("Star on GitHub")
                onClicked: Qt.openUrlExternally(SystemInfo.supportUrl)
            }
            RippleButtonWithIcon {
                materialIcon: "fork_left"
                mainText: Translation.tr("Fork the project")
                onClicked: Qt.openUrlExternally(SystemInfo.documentationUrl)
            }
        }
    }

    SettingSection {
        width: parent.width
        title: Translation.tr("TECHNICAL")

        RowLayout {
            width: parent.width
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                StyledText { text: Translation.tr("Version"); font.weight: Font.DemiBold; color: Appearance.warm.onSurfaceDim; font.pixelSize: 12 }
                StyledText { text: SystemInfo.shellVersion; font.pixelSize: 14 }
            }
            ColumnLayout {
                Layout.fillWidth: true
                StyledText { text: Translation.tr("Shell"); font.weight: Font.DemiBold; color: Appearance.warm.onSurfaceDim; font.pixelSize: 12 }
                StyledText { text: "illogical-impulse"; font.pixelSize: 14 }
            }
        }
    }
}
