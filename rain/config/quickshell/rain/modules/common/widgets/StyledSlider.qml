pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

Slider {
    id: root

    property list<real> stopIndicatorValues: [1]
    property list<real> dividerValues: []
    readonly property int wavyConfig: 4
    readonly property int xsConfig: 12
    readonly property int sConfig: 18
    readonly property int mConfig: 30
    readonly property int lConfig: 42
    readonly property int xlConfig: 72

    property int configuration: 18

    property real handleDefaultWidth: 3
    property real handlePressedWidth: 1.5
    property color highlightColor: Appearance.warm.accent
    property color trackColor: Appearance.warm.bgSurfaceLow
    property color handleColor: Appearance.warm.accent
    property color dotColor: Appearance.m3colors.m3onSecondaryContainer
    property color dotColorHighlighted: Appearance.m3colors.m3onPrimary
    property real unsharpenRadius: 0
    property real trackWidth: configuration
    property real trackRadius: configuration / 2
    property real handleHeight: (configuration === root.wavyConfig) ? 24 : Math.max(24, trackWidth + 6)
    property real handleWidth: root.pressed ? handlePressedWidth : handleDefaultWidth
    property real handleMargins: 4
    property real dividerMargins: 2
    property real trackDotSize: 3
    property bool usePercentTooltip: true
    property string tooltipContent: usePercentTooltip ? `${Math.round(((value - from) / (to - from)) * 100)}%` : `${Math.round(value)}`
    property bool wavy: configuration === root.wavyConfig
    property bool animateWave: true
    property real waveAmplitudeMultiplier: wavy ? 0.5 : 0
    property real waveFrequency: 6
    property real waveFps: 60

    leftPadding: handleMargins
    rightPadding: handleMargins
    property real effectiveDraggingWidth: width - leftPadding - rightPadding

    Layout.fillWidth: true
    from: 0
    to: 1

    Behavior on value {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMoveFast.velocity
        }
    }

    Behavior on handleMargins {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    component TrackDot: Rectangle {
        required property real value
        property real normalizedValue: (value - root.from) / (root.to - root.from)
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleMargins + (normalizedValue * root.effectiveDraggingWidth) - (root.trackDotSize / 2)
        width: root.trackDotSize
        height: root.trackDotSize
        radius: root.trackDotSize / 2
        color: normalizedValue > root.visualPosition ? root.dotColor : root.dotColorHighlighted

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = false
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    }

    background: Item {
        id: background
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        implicitHeight: trackWidth
        property var normalized: root.dividerValues.map(v => (v - root.from) / (root.to - root.from))
        property var filtered: normalized.filter(v => Math.abs(v - root.visualPosition) * effectiveDraggingWidth > handleMargins + handleWidth / 2 - dividerMargins)
        property var leftValues: [0, ...filtered.filter(v => v < root.visualPosition), root.visualPosition]
        property var rightValues: [root.visualPosition, ...filtered.filter(v => v > root.visualPosition), 1]
        property var leftWidths: leftValues.map((v, i, a) => a[i + 1] - v).slice(0, -1)
        property var rightWidths: rightValues.map((v, i, a) => a[i + 1] - v).slice(0, -1)

        Repeater {
            model: background.leftWidths.length

            Loader {
                required property real index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : 0
                property real rightMargin: index < background.leftWidths.length - 1 ? root.dividerMargins : root.handleMargins
                x: background.leftValues[index] * root.effectiveDraggingWidth + leftMargin + (index > 0 ? leftPadding : 0)
                width: background.leftWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === background.leftWidths.length - 1 ? handleWidth / 2 : 0) + (index === 0 ? leftPadding : 0)
                height: root.trackWidth
                active: !root.wavy
                sourceComponent: Rectangle {
                    color: root.highlightColor
                    radius: root.trackRadius
                }
            }
        }

        Repeater {
            model: background.leftWidths.length

            Loader {
                required property int index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : 0
                property real rightMargin: index < background.leftWidths.length - 1 ? root.dividerMargins : root.handleMargins
                x: background.leftValues[index] * root.effectiveDraggingWidth + leftMargin + (index > 0 ? leftPadding : 0)
                width: background.leftWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === background.leftWidths.length - 1 ? handleWidth / 2 : 0) + (index === 0 ? leftPadding : 0)
                height: root.height
                active: root.wavy
                sourceComponent: WavyLine {
                    id: wavyFill
                    frequency: root.waveFrequency
                    fullLength: root.width
                    color: root.highlightColor
                    amplitudeMultiplier: root.wavy ? 0.5 : 0
                    width: parent.width
                    height: root.trackWidth
                    Connections {
                        target: root
                        function onValueChanged() { wavyFill.requestPaint(); }
                        function onHighlightColorChanged() { wavyFill.requestPaint(); }
                    }
                    FrameAnimation {
                        running: root.animateWave
                        onTriggered: {
                            wavyFill.requestPaint()
                        }
                    }
                }
            }
        }

        Repeater {
            model: background.rightWidths.length

            Rectangle {
                required property int index
                anchors.verticalCenter: background.verticalCenter
                property real leftMargin: index > 0 ? root.dividerMargins : root.handleMargins
                property real rightMargin: index < background.rightWidths.length - 1 ? root.dividerMargins : 0
                x: background.rightValues[index] * root.effectiveDraggingWidth + leftMargin + (index === 0 ? handleWidth / 2 : 0) + leftPadding
                width: background.rightWidths[index] * root.effectiveDraggingWidth - leftMargin - rightMargin - (index === 0 ? handleWidth / 2 : 0) + (index === background.rightWidths.length - 1 ? rightPadding : 0)
                height: trackWidth
                color: root.trackColor
                radius: root.trackRadius
            }
        }

        Repeater {
            model: root.stopIndicatorValues
            TrackDot {
                required property real modelData
                value: modelData
                anchors.verticalCenter: parent?.verticalCenter
            }
        }
    }

    handle: Rectangle {
        id: handle

        implicitWidth: root.handleWidth
        implicitHeight: root.handleHeight
        x: root.leftPadding + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2)
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.max(1, root.handleWidth / 2)
        color: root.handleColor

        Behavior on implicitWidth {
            animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        StyledToolTip {
            extraVisibleCondition: root.pressed
            text: root.tooltipContent
            font {
                family: Appearance.font.family.numbers
                variableAxes: Appearance.font.variableAxes.numbers
            }
        }
    }
}
