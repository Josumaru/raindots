import QtQuick
import qs.modules.common
import qs.modules.common.widgets

MaterialShape {
    id: root
    property alias text: symbol.name
    property alias iconSize: symbol.size
    property alias colSymbol: symbol.tint
    property real padding: 6

    color: Appearance.colors.colSecondaryContainer
    colSymbol: Appearance.colors.colOnSecondaryContainer
    implicitSize: Math.max(symbol.implicitWidth, symbol.implicitHeight) + padding * 2

    Icon {
        id: symbol
        tint: root.colSymbol
    }
}
