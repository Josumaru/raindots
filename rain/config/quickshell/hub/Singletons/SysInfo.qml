pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// system information: hostname, OS, kernel, CPU, GPU, RAM.
Item {
    id: sys

    property string hostname: ""
    property string os: ""
    property string kernel: ""
    property string cpu: ""
    property string gpu: ""
    property int ramTotal: 0
    property int ramUsed: 0

    readonly property real ramPct: ramTotal > 0 ? ramUsed / ramTotal : 0

    Process {
        id: infoProc
        command: ["bash", "-c", "echo hostname=$(hostname); echo os=\"$(source /etc/os-release 2>/dev/null && echo $PRETTY_NAME || echo unknown)\"; echo kernel=$(uname -r); lscpu | grep 'Model name' | head -1 | sed 's/Model name:\\s*//' | sed 's/^/cpu=/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var eq = lines[i].indexOf("=");
                    if (eq < 0) continue;
                    var k = lines[i].substring(0, eq).trim();
                    var v = lines[i].substring(eq + 1).trim();
                    if (k === "hostname") sys.hostname = v;
                    else if (k === "os") sys.os = v;
                    else if (k === "kernel") sys.kernel = v;
                    else if (k === "cpu") sys.cpu = v;
                }
            }
        }
        running: true
    }

    Process {
        id: gpuProc
        command: ["bash", "-c", "lspci | grep -i vga | head -1 | sed 's/.*: //'"]
        stdout: StdioCollector {
            onStreamFinished: { sys.gpu = this.text.trim(); }
        }
    }

    Process {
        id: ramProc
        command: ["bash", "-c", "free | awk '/Mem:/ {print $2, $3}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(/\s+/);
                if (parts.length >= 2) {
                    sys.ramTotal = parseInt(parts[0]) / 1024;
                    sys.ramUsed = parseInt(parts[1]) / 1024;
                }
            }
        }
    }
}
