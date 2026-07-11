pragma Singleton
import QtQuick

// motion tokens: durations + bezier curves for consistent animation feel.
QtObject {
    readonly property int fast:       140
    readonly property int hover:      180
    readonly property int standard:   300
    readonly property int morph:      420
    readonly property int emphasized: 400
    readonly property int spatial:    500
    readonly property int effects:    200
    readonly property int effectsSlow: 360

    readonly property var emphasizedCurve: Easing.BezierSpline;
    readonly property var effectsCurve:    Easing.BezierSpline;
    readonly property var effectsSlowCurve: Easing.BezierSpline;

    readonly property real emphasizedX1: 0.18
    readonly property real emphasizedY1: 1.0
    readonly property real emphasizedX2: 0.04
    readonly property real emphasizedY2: 1.0

    readonly property real effectsX1: 0.2
    readonly property real effectsY1: 1.0
    readonly property real effectsX2: 0.4
    readonly property real effectsY2: 1.0

    readonly property real effectsSlowX1: 0.2
    readonly property real effectsSlowY1: 1.0
    readonly property real effectsSlowX2: 0.2
    readonly property real effectsSlowY2: 1.0
}
