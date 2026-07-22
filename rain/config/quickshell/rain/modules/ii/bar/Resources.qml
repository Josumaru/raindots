import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    component NetworkSpeedIndicator: Item {
        id: netItem
        property string direction: "down"
        property string displayText: "0 B/s"
        clip: true
        visible: width > 0 && height > 0
        implicitWidth: netRowLayout.x < 0 ? 0 : netRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.barHeight
        property bool netShown: true

        RowLayout {
            id: netRowLayout
            spacing: 2
            x: netShown ? 0 : -netRowLayout.width
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                name: direction === "down" ? "arrow_down" : "arrow_up"
                size: Appearance.font.pixelSize.normal
                tint: Appearance.m3colors.m3onSecondaryContainer
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: speedTextMetrics.width
                implicitHeight: speedLabel.implicitHeight

                TextMetrics {
                    id: speedTextMetrics
                    text: "99 MB/s"
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                StyledText {
                    id: speedLabel
                    anchors.centerIn: parent
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: displayText
                }
            }

            Behavior on x {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
        }
    }

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            iconName: "cpu"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        // NetworkSpeedIndicator {
        //     direction: "down"
        //     displayText: NetworkSpeed.downloadSpeedFormatted
        //     netShown: Config.options.bar.resources.alwaysShowCpu || 
        //         !(MprisController.activePlayer?.trackTitle?.length > 0) ||
        //         root.alwaysShowAllResources
        //     Layout.leftMargin: netShown ? 6 : 0
        // }

        // NetworkSpeedIndicator {
        //     direction: "up"
        //     displayText: NetworkSpeed.uploadSpeedFormatted
        //     netShown: Config.options.bar.resources.alwaysShowCpu || 
        //         !(MprisController.activePlayer?.trackTitle?.length > 0) ||
        //         root.alwaysShowAllResources
        //     Layout.leftMargin: netShown ? 6 : 0
        // }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
