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
    // Cap bar count — tiny bars (small barWidth/spacing) otherwise explode the canvas work.
    readonly property real barExtent: verticalLayout ? screenHeight : screenWidth
    readonly property int barCount: Math.min(200, Math.max(1, Math.floor(barExtent / (barWidth + barSpacing))))
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

    function roundRectPath(ctx, x, y, w, h, rTL, rTR, rBR, rBL) {
        rTL = Math.min(rTL, w / 2, h / 2)
        rTR = Math.min(rTR, w / 2, h / 2)
        rBR = Math.min(rBR, w / 2, h / 2)
        rBL = Math.min(rBL, w / 2, h / 2)
        ctx.beginPath()
        ctx.moveTo(x + rTL, y)
        ctx.lineTo(x + w - rTR, y)
        ctx.arcTo(x + w, y, x + w, y + rTR, rTR)
        ctx.lineTo(x + w, y + h - rBR)
        ctx.arcTo(x + w, y + h, x + w - rBR, y + h, rBR)
        ctx.lineTo(x + rBL, y + h)
        ctx.arcTo(x, y + h, x, y + h - rBL, rBL)
        ctx.lineTo(x, y + rTL)
        ctx.arcTo(x, y, x + rTL, y, rTL)
        ctx.closePath()
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

    Canvas {
        id: canvas
        anchors.fill: parent
        opacity: root.activityOpacity
        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Connections {
            target: root
            function onPointsChanged() { canvas.requestPaint() }
            function onBarCountChanged() { canvas.requestPaint() }
            function onEffectiveSpacingChanged() { canvas.requestPaint() }
            function onBarWidthChanged() { canvas.requestPaint() }
            function onMaxBarHeightChanged() { canvas.requestPaint() }
            function onMaxVisualizerValueChanged() { canvas.requestPaint() }
            function onDirectionChanged() { canvas.requestPaint() }
            function onOrientationChanged() { canvas.requestPaint() }
        }

        onWidthChanged: () => canvas.requestPaint()
        onHeightChanged: () => canvas.requestPaint()

        onPaint: {
            const ctx = canvas.getContext("2d")
            ctx.clearRect(0, 0, canvas.width, canvas.height)

            const count = root.barCount
            if (count === 0) return

            const maxV = root.maxVisualizerValue || 1
            const raw = root.points
            const rawLen = raw.length

            const vals = new Array(count)
            if (rawLen === 0) {
                vals.fill(0)
            } else {
                const rawLenM1 = rawLen - 1
                const mapped = new Array(count)
                for (let i = 0; i < count; i++) {
                    const progress = i / (count - 1 || 1)
                    const relPos = progress * rawLenM1
                    const low = Math.floor(relPos)
                    const high = Math.ceil(relPos)
                    const mix = relPos - low
                    mapped[i] = (raw[low] * (1 - mix)) + (raw[high] * (high < rawLen ? mix : 0))
                }
                const sW = 0.2
                for (let j = 0; j < count; j++) {
                    const p = mapped[Math.max(0, j - 1)]
                    const n = mapped[Math.min(count - 1, j + 1)]
                    vals[j] = (p * sW) + (mapped[j] * (1.0 - 2 * sW)) + (n * sW)
                }
            }

            const radius = root.barWidth / 2
            if (!root.verticalLayout) {
                const up = root.direction === "up"
                const total = count * root.barWidth + (count - 1) * root.effectiveSpacing
                let x = (canvas.width - total) / 2
                for (let i = 0; i < count; i++) {
                    const h = Math.max(root.barWidth, (vals[i] / maxV) * root.maxBarHeight)
                    const y = up ? canvas.height - h : 0
                    ctx.fillStyle = root.colorForLevel(Math.round((h / root.maxBarHeight) * 20))
                    root.roundRectPath(ctx, x, y, root.barWidth, h,
                        up ? radius : 0, up ? radius : 0,
                        up ? 0 : radius, up ? 0 : radius)
                    ctx.fill()
                    x += root.barWidth + root.effectiveSpacing
                }
            } else {
                const growRight = root.direction === "right"
                const roundedFarSide = root.direction === "left"
                const total = count * root.barWidth + (count - 1) * root.effectiveSpacing
                let y = (canvas.height - total) / 2
                for (let i = 0; i < count; i++) {
                    const w = Math.max(root.barWidth, (vals[i] / maxV) * root.maxBarHeight)
                    const x = growRight ? 0 : canvas.width - w
                    ctx.fillStyle = root.colorForLevel(Math.round((w / root.maxBarHeight) * 20))
                    root.roundRectPath(ctx, x, y, w, root.barWidth,
                        radius, roundedFarSide ? radius : 0,
                        roundedFarSide ? radius : 0, radius)
                    ctx.fill()
                    y += root.barWidth + root.effectiveSpacing
                }
            }
        }
    }
}
