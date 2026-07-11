pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property string label: ""
    property string unit: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1
    property int decimals: 0
    signal modified(real value)

    implicitWidth: 320
    implicitHeight: 38

    function clampq(v) {
        var c = Math.max(root.from, Math.min(root.to, v));
        var p = Math.pow(10, root.decimals);
        return Math.round(c * p) / p;
    }
    function bump(dir) { root.modified(root.clampq(root.value + dir * root.step)); }

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - field.width - 14
        elide: Text.ElideRight
        text: root.label
        color: Appearance.warm.onSurface
        font.pixelSize: 14
        font.weight: Font.Medium
    }

    Row {
        id: field
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        component StepKey: Rectangle {
            id: key
            property string glyph: "+"
            property int dir: 1
            width: 30
            height: 30
            color: tap.pressed ? Appearance.warm.bgSurfaceHigh : (hov.hovered ? Appearance.warm.bgSurface : Appearance.warm.bgSurfaceLow)
            border.width: 1
            border.color: hov.hovered ? Appearance.warm.accent : Appearance.warm.hairline
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            StyledText {
                anchors.centerIn: parent
                text: key.glyph
                color: hov.hovered ? Appearance.warm.onSurface : Appearance.warm.onSurfaceDim
                font.pixelSize: key.glyph === "\u2212" ? 17 : 15
                font.family: Appearance.font.family.mono
                font.weight: Font.DemiBold
            }

            HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: tap; onTapped: root.bump(key.dir) }
            Timer {
                interval: 90; repeat: true
                running: tap.pressed
                triggeredOnStart: false
                onTriggered: root.bump(key.dir)
            }
        }

        StepKey { anchors.verticalCenter: parent.verticalCenter; glyph: "\u2212"; dir: -1 }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 86
            height: 30
            color: Appearance.warm.bgSurfaceLow
            border.width: 1
            border.color: input.activeFocus ? Appearance.warm.accent : Appearance.warm.hairline
            Behavior on border.color { ColorAnimation { duration: 120 } }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.rightMargin: root.unit !== "" ? 22 : 0
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                text: root.value.toFixed(root.decimals)
                color: Appearance.warm.onSurface
                font.family: Appearance.font.family.mono
                font.pixelSize: 14
                font.weight: Font.DemiBold
                selectByMouse: true
                clip: true
                validator: DoubleValidator {
                    bottom: root.from
                    top: root.to
                    decimals: root.decimals
                    notation: DoubleValidator.StandardNotation
                }
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onActiveFocusChanged: {
                    if (activeFocus)
                        selectAll();
                    else
                        text = Qt.binding(() => root.value.toFixed(root.decimals));
                }
                onEditingFinished: {
                    var v = parseFloat(text);
                    if (!isNaN(v)) {
                        var q = root.clampq(v);
                        root.modified(q);
                        text = q.toFixed(root.decimals);
                    }
                }
            }

            StyledText {
                visible: root.unit !== ""
                anchors.right: parent.right
                anchors.rightMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: root.unit
                color: Appearance.warm.onSurfaceDim
                font.pixelSize: 11
                font.family: Appearance.font.family.mono
                font.weight: Font.Medium
            }
        }

        StepKey { anchors.verticalCenter: parent.verticalCenter; glyph: "+"; dir: 1 }
    }
}
