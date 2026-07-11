import QtQuick
import "Singletons"

// Editorial kicker: a short vermillion tick, then a mono uppercase label.
Row {
    id: eye

    property string text: ""
    property bool mark: true
    property color tick: Theme.sun
    property color labelColor: Theme.dim

    spacing: 10

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 22; height: 1.5; color: eye.tick
    }

    Text {
        visible: eye.mark
        anchors.verticalCenter: parent.verticalCenter
        text: "力"; color: eye.tick
        font.family: Theme.fontJp; font.pixelSize: 12; font.weight: Font.Bold; opacity: 0.9
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: eye.text; color: eye.labelColor
        font.family: Theme.mono; font.pixelSize: 10; font.weight: Font.DemiBold
        font.letterSpacing: 3.2; font.capitalization: Font.AllUppercase
    }
}
