pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property string downloadSpeedFormatted: "0 B/s"
    property string uploadSpeedFormatted: "0 B/s"

    property var _previousStats: null

    function _formatSpeed(bytesPerSec) {
        if (bytesPerSec < 0) return "0 B/s"
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(0) + " KB/s"
        return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
    }

    function _processOutput(text) {
        const lines = text.split('\n')
        let totalRx = 0
        let totalTx = 0

        for (let i = 2; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line) continue
            const parts = line.split(/\s+/)
            const iface = parts[0].replace(':', '')
            if (iface === "lo") continue

            totalRx += parseInt(parts[1]) || 0
            totalTx += parseInt(parts[9]) || 0
        }

        if (root._previousStats !== null) {
            const deltaRx = totalRx - root._previousStats.totalRx
            const deltaTx = totalTx - root._previousStats.totalTx
            const interval = pollTimer.interval / 1000

            root.downloadSpeed = Math.max(0, deltaRx / interval)
            root.uploadSpeed = Math.max(0, deltaTx / interval)
        }

        root._previousStats = { totalRx, totalTx }
        root.downloadSpeedFormatted = root._formatSpeed(root.downloadSpeed)
        root.uploadSpeedFormatted = root._formatSpeed(root.uploadSpeed)
    }

    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            netDevProc.running = false
            Qt.callLater(() => { netDevProc.running = true })
        }
    }

    Process {
        id: netDevProc
        command: ["sh", "-c", "cat /proc/net/dev 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._processOutput(text)
            }
        }
    }

    Component.onCompleted: {
        netDevProc.running = true
    }
}
