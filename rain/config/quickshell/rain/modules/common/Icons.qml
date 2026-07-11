pragma Singleton

// From https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import qs.services

Singleton {
    id: root

    function getBatteryIcon(percentage: int): string {
        return "battery";
    }

    function getBluetoothDeviceMaterialSymbol(systemIconName: string): string {
        if (systemIconName.includes("headset") || systemIconName.includes("headphones"))
            return "headphones";
        if (systemIconName.includes("audio"))
            return "volume_up";
        if (systemIconName.includes("phone"))
            return "display";
        if (systemIconName.includes("mouse"))
            return "mouse";
        if (systemIconName.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    function getNetworkMaterialSymbol() {
        if (Network.ethernet) return "wifi";
        if (Network.wifiEnabled && Network.wifiStatus === "connected") {
            const strength = Network.active?.strength ?? 0
            if (strength > 83) return "wifi";
            if (strength > 67) return "wifi";
            if (strength > 50) return "wifi";
            if (strength > 33) return "wifi";
            if (strength > 17) return "wifi";
            return "wifi_off"
        } else {
            if (Network.wifiStatus === "connecting") return "wifi_off";
            if (Network.wifiStatus === "disconnected") return "wifi";
            if (Network.wifiStatus === "disabled") return "wifi_off";
            return "wifi_off";
        }
    }

    readonly property var weatherIconMap: ({
        "113": "sun",
        "116": "cloud",
        "119": "cloud",
        "122": "cloud",
        "143": "cloud",
        "176": "cloud",
        "179": "cloud",
        "182": "cloud",
        "185": "cloud",
        "200": "cloud",
        "227": "cloud",
        "230": "cloud",
        "248": "cloud",
        "260": "cloud",
        "263": "cloud",
        "266": "cloud",
        "281": "cloud",
        "284": "cloud",
        "293": "cloud",
        "296": "cloud",
        "299": "cloud",
        "302": "cloud",
        "305": "cloud",
        "308": "cloud",
        "311": "cloud",
        "314": "cloud",
        "317": "cloud",
        "320": "cloud",
        "323": "cloud",
        "326": "cloud",
        "329": "cloud",
        "332": "cloud",
        "335": "cloud",
        "338": "cloud",
        "350": "cloud",
        "353": "cloud",
        "356": "cloud",
        "359": "cloud",
        "362": "cloud",
        "365": "cloud",
        "368": "cloud",
        "371": "cloud",
        "374": "cloud",
        "377": "cloud",
        "386": "cloud",
        "389": "cloud",
        "392": "cloud",
        "395": "cloud"
    })

    
    function getWeatherIcon(code) {
        const key = String(code)
        if (weatherIconMap.hasOwnProperty(key)) {
            return weatherIconMap[key]
        }
    }
}
