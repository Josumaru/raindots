import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        implicitWidth: Math.max(header.implicitWidth, gridLayout.implicitWidth)
        implicitHeight: gridLayout.implicitHeight
        spacing: 5

        // Header
        ColumnLayout {
            id: header
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Icon {
                    name: "pin"
                    size: Appearance.font.pixelSize.large
                    tint: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: Weather.data.city
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
            StyledText {
                id: temp
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                text: Weather.data.temp + " • " + Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike)
            }
        }

        // Metrics grid
        GridLayout {
            id: gridLayout
            columns: 2
            rowSpacing: 5
            columnSpacing: 5
            uniformCellWidths: true

            WeatherCard {
                title: Translation.tr("UV Index")
                symbol: "sun"
                value: Weather.data.uv
            }
            WeatherCard {
                title: Translation.tr("Wind")
                symbol: "compass"
                value: `(${Weather.data.windDir}) ${Weather.data.wind}`
            }
            WeatherCard {
                title: Translation.tr("Precipitation")
                symbol: "cloud"
                value: Weather.data.precip
            }
            WeatherCard {
                title: Translation.tr("Humidity")
                symbol: "cloud"
                value: Weather.data.humidity
            }
            WeatherCard {
                title: Translation.tr("Visibility")
                symbol: "eye"
                value: Weather.data.visib
            }
            WeatherCard {
                title: Translation.tr("Pressure")
                symbol: "star"
                value: Weather.data.press
            }
            WeatherCard {
                title: Translation.tr("Sunrise")
                symbol: "moon"
                value: Weather.data.sunrise
            }
            WeatherCard {
                title: Translation.tr("Sunset")
                symbol: "moon"
                value: Weather.data.sunset
            }
        }

        // Footer: last refresh
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Last refresh: %1").arg(Weather.data.lastRefresh)
            font {
                weight: Font.Medium
                pixelSize: Appearance.font.pixelSize.smaller
            }
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
}
