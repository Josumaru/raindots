import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Runs cava to feed audio amplitude data into points. Shared by the
 * background equalizer widget and the media controls popup.
 */
Singleton {
    id: root

    property bool available: false
    property list<real> points: []
    readonly property bool running: cavaProc.running

    readonly property bool enabled: Config.ready && Config.options.background.widgets.visualizer.enable

    Process {
        id: availabilityProc
        running: true
        command: ["bash", "-c", "command -v cava"]
        onExited: (exitCode, exitStatus) => {
            root.available = exitCode === 0
        }
    }

    Process {
        id: cavaProc
        running: root.available && (root.enabled || GlobalStates.mediaControlsOpen)
        onRunningChanged: {
            if (!cavaProc.running) {
                root.points = []
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                // Parse `;`-separated values into the points array
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.points = points;
            }
        }
    }
}
