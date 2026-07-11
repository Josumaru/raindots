import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 0.01
    property int decimals: 2
    property bool percent: false
    signal modified(real value)

    implicitWidth: 320
    implicitHeight: 38

    readonly property string readout: root.percent
        ? Math.round(root.value * 100) + "%"
        : root.value.toFixed(root.decimals)

    StyledText {
        id: lbl
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 116
        elide: Text.ElideRight
        text: root.label
        color: Appearance.warm.onSurface
        font.pixelSize: 14
        font.weight: Font.Medium
    }

    StyledText {
        id: val
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        horizontalAlignment: Text.AlignRight
        text: root.readout
        color: Appearance.warm.onSurface
        font.pixelSize: 13
        font.family: Appearance.font.family.mono
        font.weight: Font.DemiBold
    }

    StyledSlider {
        anchors.left: lbl.right
        anchors.right: val.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        from: root.from
        to: root.to
        stepSize: root.step
        value: root.value
        onMoved: (v) => root.modified(v)
    }
}
