import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Internet")
        statusText: Network.vpnEnabled ? Translation.tr("VPN: %1").arg(Network.vpnName) : Network.networkName
    tooltipText: Translation.tr("%1 | Right-click to configure").arg(Network.networkName)
    icon: Network.materialSymbol

    toggled: Network.wifiStatus !== "disabled"
    mainAction: () => Network.toggleWifi()
    hasMenu: true
}
