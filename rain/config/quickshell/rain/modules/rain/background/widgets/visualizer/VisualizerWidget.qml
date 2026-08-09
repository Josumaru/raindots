import QtQuick
import qs.services
import qs.modules.common
import qs.modules.rain.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "visualizer"

    readonly property list<real> points: Visualizer.points

    // Editable placement & look
    property string position: configEntry.position // "bottom" | "top" | "left" | "right"
    property string orientation: configEntry.orientation // "horizontal" | "vertical"
    property string direction: configEntry.direction // horizontal: "up" | "down"; vertical: "right" | "left"
    property real edgeOffset: configEntry.offset
    property real barWidth: configEntry.barWidth
    property real barSpacing: configEntry.barSpacing
    property real maxBarHeight: configEntry.maxBarHeight
    property real maxVisualizerValue: configEntry.maxVisualizerValue
    property real smoothingDuration: configEntry.smoothingDuration

    readonly property bool verticalLayout: orientation === "vertical"
    // Cap bar count — tiny bars (small barWidth/spacing) otherwise explode the item count.
    readonly property real barExtent: verticalLayout ? screenHeight : screenWidth
    readonly property int barCount: Math.min(120, Math.max(1, Math.floor(barExtent / (barWidth + barSpacing))))
    // When the cap kicks in, grow the spacing so the bars still span the full edge.
    readonly property real effectiveSpacing: barCount > 1 ? Math.max(barSpacing, (barExtent - barCount * barWidth) / (barCount - 1)) : barSpacing

    function colorForLevel(level) {
        const t = level / 20
        return Qt.rgba(
            Appearance.colors.colPrimary.r * t + Appearance.colors.colPrimaryContainer.r * (1 - t),
            Appearance.colors.colPrimary.g * t + Appearance.colors.colPrimaryContainer.g * (1 - t),
            Appearance.colors.colPrimary.b * t + Appearance.colors.colPrimaryContainer.b * (1 - t),
            1
        )
    }

    readonly property var smoothedPoints: {
        let raw = points
        if (!raw || raw.length === 0) return Array(barCount).fill(0)
        let count = barCount
        let mapped = new Array(count)
        let rawLenM1 = raw.length - 1

        for (let i = 0; i < count; i++) {
            let progress = i / (count - 1 || 1)
            let relPos = progress * rawLenM1
            let low = Math.floor(relPos)
            let high = Math.ceil(relPos)
            let mix = relPos - low
            mapped[i] = (raw[low] * (1 - mix)) + (raw[high] * (high < raw.length ? mix : 0))
        }

        let smoothed = new Array(count)
        let sW = 0.2
        for (let j = 0; j < count; j++) {
            let p = mapped[Math.max(0, j - 1)]
            let n = mapped[Math.min(count - 1, j + 1)]
            smoothed[j] = (p * sW) + (mapped[j] * (1.0 - 2 * sW)) + (n * sW)
        }
        return smoothed
    }

    function valueAt(i) {
        const v = root.smoothedPoints[i] ?? 0
        return Math.max(root.barWidth, (v / root.maxVisualizerValue) * root.maxBarHeight)
    }

    property real activityOpacity: Visualizer.running ? 1.0 : 0.0
    Behavior on activityOpacity {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    // Not draggable; pinned to the selected edge.
    draggable: false
    implicitWidth: verticalLayout ? maxBarHeight + 20 : screenWidth
    implicitHeight: verticalLayout ? screenHeight : maxBarHeight + 20
    property real targetX: {
        if (verticalLayout) return position === "left" ? root.edgeOffset : screenWidth - width - root.edgeOffset
        return (screenWidth - width) / 2
    }
    property real targetY: {
        if (verticalLayout) return (screenHeight - height) / 2
        return position === "bottom" ? screenHeight - height - root.edgeOffset : root.edgeOffset
    }

    // Horizontal bars (bottom/top) — grow up or down.
    Row {
        visible: !root.verticalLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: root.effectiveSpacing
        opacity: root.activityOpacity
        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                width: root.barWidth
                property real pointValue: root.valueAt(index)
                height: pointValue
                anchors.bottom: root.direction === "up" ? parent.bottom : undefined
                anchors.top: root.direction === "down" ? parent.top : undefined
                topLeftRadius: root.barWidth / 2
                topRightRadius: root.barWidth / 2
                bottomLeftRadius: root.direction === "down" ? root.barWidth / 2 : 0
                bottomRightRadius: root.direction === "down" ? root.barWidth / 2 : 0

                property int intensityLevel: Math.round((pointValue / root.maxBarHeight) * 20)
                color: root.colorForLevel(intensityLevel)
            }
        }
    }

    // Vertical bars (left/right) — grow right or left.
    Column {
        visible: root.verticalLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: root.effectiveSpacing
        opacity: root.activityOpacity
        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                height: root.barWidth
                property real pointValue: root.valueAt(index)
                width: pointValue
                anchors.left: root.direction === "right" ? parent.left : undefined
                anchors.right: root.direction === "left" ? parent.right : undefined
                topLeftRadius: root.barWidth / 2
                bottomLeftRadius: root.barWidth / 2
                topRightRadius: root.direction === "left" ? root.barWidth / 2 : 0
                bottomRightRadius: root.direction === "left" ? root.barWidth / 2 : 0

                property int intensityLevel: Math.round((pointValue / root.maxBarHeight) * 20)
                color: root.colorForLevel(intensityLevel)
            }
        }
    }
}
