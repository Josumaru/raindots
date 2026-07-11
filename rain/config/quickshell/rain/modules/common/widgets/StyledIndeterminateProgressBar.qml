import qs.modules.common
import QtQuick
import QtQuick.Controls

ProgressBar {
    indeterminate: true

    background: Rectangle {
        color: Appearance.m3colors.m3surfaceContainerLow
    }

    contentItem: Item {
        implicitHeight: 4

        Rectangle {
            width: parent.width * 0.3
            height: parent.height
            color: Appearance.colors.colPrimary

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.indeterminate
                PropertyAnimation {
                    from: -parent.width * 0.3
                    to: parent.width
                    duration: 1400
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
