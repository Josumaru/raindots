pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    // Only the interacted monitor grabs the keyboard so Enter always lands on the right instance
    WlrLayershell.keyboardFocus: GlobalStates.regionSelectorActiveScreen === "" || GlobalStates.regionSelectorActiveScreen === root.screen.name
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Modes
    // TODO: Ask: sidebar AI
    enum SnipAction { Copy, Edit, Search, CharRecognition, Record, RecordWithSound } 
    enum SelectionMode { RectCorners, Circle }
    enum Phase { Select, Adjust, Post }
    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    property var phase: RegionSelection.Phase.Select
    signal dismiss()

    // Styles
    property string screenshotDir: Directories.screenshotTemp
    property color overlayColor: ColorUtils.transparentize("#000000", 0.4)
    property color brightText: Appearance.m3colors.darkmode ? Appearance.colors.colOnLayer0 : Appearance.colors.colLayer0
    property color brightSecondary: Appearance.m3colors.darkmode ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondary
    property color brightTertiary: Appearance.m3colors.darkmode ? Appearance.colors.colTertiary : Qt.lighter(Appearance.colors.colPrimary)
    property color selectionBorderColor: ColorUtils.mix(brightText, brightSecondary, 0.5)
    property color selectionFillColor: "#33ffffff"
    property color windowBorderColor: brightSecondary
    property color windowFillColor: ColorUtils.transparentize(windowBorderColor, 0.85)
    property color imageBorderColor: brightTertiary
    property color imageFillColor: ColorUtils.transparentize(imageBorderColor, 0.85)
    property color onBorderColor: "#ff000000"
    property real targetRegionOpacity: Config.options.regionSelector.targetRegions.opacity
    property bool contentRegionOpacity: Config.options.regionSelector.targetRegions.contentRegionOpacity

    // Vars for indicators
    readonly property var windows: [...HyprlandData.windowList].sort((a, b) => {
        // Sort floating=true windows before others
        if (a.floating === b.floating) return 0;
        return a.floating ? -1 : 1;
    })
    readonly property var layers: HyprlandData.layers
    readonly property real falsePositivePreventionRatio: 0.5

    // Screen & interaction vars
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale
    readonly property real monitorOffsetX: hyprlandMonitor.x
    readonly property real monitorOffsetY: hyprlandMonitor.y
    property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property list<point> points: []
    property var mouseButton: null
    property var imageRegions: []
    readonly property list<var> windowRegions: RegionFunctions.filterWindowRegionsByLayers(
        root.windows.filter(w => w.workspace.id === root.activeWorkspaceId),
        root.layerRegions
    ).map(window => {
        return {
            at: [window.at[0] - root.monitorOffsetX, window.at[1] - root.monitorOffsetY],
            size: [window.size[0], window.size[1]],
            class: window.class,
            title: window.title,
        }
    })
    readonly property list<var> layerRegions: {
        const layersOfThisMonitor = root.layers[root.hyprlandMonitor.name]
        const topLayers = layersOfThisMonitor?.levels["2"]
        if (!topLayers) return [];
        const nonBarTopLayers = topLayers
            .filter(layer => !(layer.namespace.includes(":bar") || layer.namespace.includes(":verticalBar") || layer.namespace.includes(":dock")))
            .map(layer => {
            return {
                at: [layer.x, layer.y],
                size: [layer.w, layer.h],
                namespace: layer.namespace,
            }
        })
        const offsetAdjustedLayers = nonBarTopLayers.map(layer => {
            return {
                at: [layer.at[0] - root.monitorOffsetX, layer.at[1] - root.monitorOffsetY],
                size: layer.size,
                namespace: layer.namespace,
            }
        });
        return offsetAdjustedLayers;
    }

    // Config
    property bool isCircleSelection: (root.selectionMode === RegionSelection.SelectionMode.Circle)
    property bool enableWindowRegions: Config.options.regionSelector.targetRegions.windows && !isCircleSelection
    property bool enableLayerRegions: Config.options.regionSelector.targetRegions.layers && !isCircleSelection
    property bool enableContentRegions: Config.options.regionSelector.targetRegions.content

    // Target
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    function targetedRegionValid() {
        return (root.targetedRegionX >= 0 && root.targetedRegionY >= 0)
    }
    function setRegionToTargeted() {
        const padding = Config.options.regionSelector.targetRegions.selectionPadding; // Make borders not cut off n stuff
        root.selX = root.targetedRegionX - padding;
        root.selY = root.targetedRegionY - padding;
        root.selW = root.targetedRegionWidth + padding * 2;
        root.selH = root.targetedRegionHeight + padding * 2;
    }

    function updateTargetedRegion(x, y) {
        // Image regions
        const clickedRegion = root.imageRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedRegion) {
            root.targetedRegionX = clickedRegion.at[0];
            root.targetedRegionY = clickedRegion.at[1];
            root.targetedRegionWidth = clickedRegion.size[0];
            root.targetedRegionHeight = clickedRegion.size[1];
            return;
        }

        // Layer regions
        const clickedLayer = root.layerRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedLayer) {
            root.targetedRegionX = clickedLayer.at[0];
            root.targetedRegionY = clickedLayer.at[1];
            root.targetedRegionWidth = clickedLayer.size[0];
            root.targetedRegionHeight = clickedLayer.size[1];
            return;
        }

        // Window regions
        const clickedWindow = root.windowRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedWindow) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
            return;
        }

        root.targetedRegionX = -1;
        root.targetedRegionY = -1;
        root.targetedRegionWidth = 0;
        root.targetedRegionHeight = 0;
    }

    // Current selection rectangle (logical px)
    property real selX: 0
    property real selY: 0
    property real selW: 0
    property real selH: 0

    // Adjust phase state
    readonly property real adjustMargin: 8
    readonly property real minSelSize: 4
    property string adjustMode: "" // "", "move", "resize", "redraw"
    property string resizeZone: ""
    property string hoverZone: ""
    property point adjustPressPos: Qt.point(0, 0)
    property var adjustOrigSel: ({ "x": 0, "y": 0, "w": 0, "h": 0 })

    // Last selection memory (per screen, persisted)
    readonly property string lastRegionFilePath: FileUtils.trimFileProtocol(`${Directories.state}/user/region-selector.json`)
    property var rememberedRegions: ({})
    property bool rememberedApplied: false

    // Screenshot stuff
    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            if (root.enableContentRegions) imageDetectionProcess.running = true;
            root.preparationDone = !checkRecordingProc.running;
        }
    }
    property bool isRecording: root.action === RegionSelection.SnipAction.Record || root.action === RegionSelection.SnipAction.RecordWithSound
    property bool recordingShouldStop: false
    Process {
        id: checkRecordingProc
        running: isRecording
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = !screenshotProc.running
            root.recordingShouldStop = (exitCode === 0);
        }
    }
    property bool preparationDone: false
    onPreparationDoneChanged: {
        if (!preparationDone) return;
        if (root.isRecording && root.recordingShouldStop) {
            Quickshell.execDetached([Directories.recordScriptPath]);
            root.dismiss();
            return;
        }
        root.applyRememberedRegion();
        root.visible = true;
    }

    // Last selection persistence
    FileView {
        id: lastRegionFile
        path: Qt.resolvedUrl(root.lastRegionFilePath)
        onLoaded: {
            try {
                root.rememberedRegions = JSON.parse(lastRegionFile.text() || "{}");
            } catch (e) {
                root.rememberedRegions = {};
            }
        }
        onLoadFailed: (error) => {
            root.rememberedRegions = {};
        }
    }
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", FileUtils.trimFileProtocol(`${Directories.state}/user`)]);
    }

    function applyRememberedRegion() {
        if (root.rememberedApplied) return;
        root.rememberedApplied = true;
        const r = root.rememberedRegions[root.screen.name];
        if (!r) return;
        const w = Math.min(r.width ?? 0, root.screen.width);
        const h = Math.min(r.height ?? 0, root.screen.height);
        if (w < root.minSelSize * 2 || h < root.minSelSize * 2) return;
        root.selW = w;
        root.selH = h;
        root.selX = Math.max(0, Math.min(r.x ?? 0, root.screen.width - w));
        root.selY = Math.max(0, Math.min(r.y ?? 0, root.screen.height - h));
        keyHandler.forceActiveFocus();
        if (GlobalStates.regionSelectorActiveScreen === "")
            GlobalStates.regionSelectorActiveScreen = root.screen.name;
        root.phase = RegionSelection.Phase.Adjust;
    }

    function rememberSelection() {
        let data = {};
        try {
            data = JSON.parse(lastRegionFile.text() || "{}");
        } catch (e) {}
        data[root.screen.name] = {
            "x": Math.round(root.selX),
            "y": Math.round(root.selY),
            "width": Math.round(root.selW),
            "height": Math.round(root.selH),
        };
        lastRegionFile.setText(JSON.stringify(data));
    }

    Process {
        id: imageDetectionProcess
        command: ["bash", "-c", `${Directories.scriptPath}/images/find-regions-venv.sh ` 
            + `--hyprctl ` 
            + `--image '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}' ` 
            + `--max-width ${Math.round(root.screen.width * root.falsePositivePreventionRatio)} ` 
            + `--max-height ${Math.round(root.screen.height * root.falsePositivePreventionRatio)} `]
        stdout: StdioCollector {
            id: imageDimensionCollector
            onStreamFinished: {
                imageRegions = RegionFunctions.filterImageRegions(
                    JSON.parse(imageDimensionCollector.text),
                    root.windowRegions
                );
            }
        }
    }

    function getScreenshotAction() {
        switch(root.action) {
            case RegionSelection.SnipAction.Copy:
                return ScreenshotAction.Action.Copy;
            case RegionSelection.SnipAction.Edit:
                return ScreenshotAction.Action.Edit;
            case RegionSelection.SnipAction.Search:
                return ScreenshotAction.Action.Search;
            case RegionSelection.SnipAction.CharRecognition:
                return ScreenshotAction.Action.CharRecognition;
            case RegionSelection.SnipAction.Record:
                return ScreenshotAction.Action.Record;
            case RegionSelection.SnipAction.RecordWithSound:
                return ScreenshotAction.Action.RecordWithSound;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                root.dismiss();
                return;
        }
    }

    function clampSelection() {
        root.selX = Math.max(0, Math.min(root.selX, root.screen.width - root.selW));
        root.selY = Math.max(0, Math.min(root.selY, root.screen.height - root.selH));
        root.selW = Math.max(0, Math.min(root.selW, root.screen.width - root.selX));
        root.selH = Math.max(0, Math.min(root.selH, root.screen.height - root.selY));
    }

    // Selection finished (mouse released in Select phase) -> enter Adjust phase
    function finishSelection() {
        root.dragging = false;
        if ((root.action === RegionSelection.SnipAction.Copy || root.action === RegionSelection.SnipAction.Edit)
            && root.mouseButton === Qt.RightButton) {
            root.action = RegionSelection.SnipAction.Edit;
        }
        root.points = [];
        if (root.selW < root.minSelSize || root.selH < root.minSelSize) {
            if (!root.targetedRegionValid()) root.dismiss();
            return;
        }
        root.clampSelection();
        keyHandler.forceActiveFocus();
        root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        root.phase = RegionSelection.Phase.Adjust;
    }

    function zoneAt(x, y) {
        const m = root.adjustMargin;
        const nearL = Math.abs(x - root.selX) <= m;
        const nearR = Math.abs(x - (root.selX + root.selW)) <= m;
        const nearT = Math.abs(y - root.selY) <= m;
        const nearB = Math.abs(y - (root.selY + root.selH)) <= m;
        const inside = x > root.selX && x < root.selX + root.selW && y > root.selY && y < root.selY + root.selH;
        let vert = "";
        let horiz = "";
        if (nearT) vert = "n";
        else if (nearB) vert = "s";
        if (nearL) horiz = "w";
        else if (nearR) horiz = "e";
        if (vert === "" && horiz === "") return inside ? "move" : "outside";
        return `${vert}${horiz}`;
    }

    function adjustPressed(x, y) {
        const zone = zoneAt(x, y);
        if (zone === "outside") {
            // Start drawing a new selection from scratch
            root.adjustMode = "redraw";
            root.dragStartX = x;
            root.dragStartY = y;
            root.selX = x;
            root.selY = y;
            root.selW = 0;
            root.selH = 0;
            return;
        }
        root.adjustOrigSel = { "x": root.selX, "y": root.selY, "w": root.selW, "h": root.selH };
        root.adjustPressPos = Qt.point(x, y);
        root.resizeZone = zone;
        root.adjustMode = (zone === "move") ? "move" : "resize";
    }

    function adjustMoved(x, y) {
        if (root.adjustMode === "") {
            root.hoverZone = zoneAt(x, y);
            return;
        }
        if (root.adjustMode === "redraw") {
            root.selX = Math.min(root.dragStartX, x);
            root.selY = Math.min(root.dragStartY, y);
            root.selW = Math.abs(x - root.dragStartX);
            root.selH = Math.abs(y - root.dragStartY);
            return;
        }
        const dx = x - root.adjustPressPos.x;
        const dy = y - root.adjustPressPos.y;
        const o = root.adjustOrigSel;
        const minSize = root.minSelSize;
        if (root.adjustMode === "move") {
            root.selX = Math.max(0, Math.min(o.x + dx, root.screen.width - o.w));
            root.selY = Math.max(0, Math.min(o.y + dy, root.screen.height - o.h));
            return;
        }
        // resize
        const z = root.resizeZone;
        if (z.includes("w")) {
            const nx = Math.max(0, Math.min(o.x + dx, o.x + o.w - minSize));
            root.selX = nx;
            root.selW = o.x + o.w - nx;
        } else if (z.includes("e")) {
            root.selW = Math.max(minSize, Math.min(o.w + dx, root.screen.width - o.x));
        }
        if (z.includes("n")) {
            const ny = Math.max(0, Math.min(o.y + dy, o.y + o.h - minSize));
            root.selY = ny;
            root.selH = o.y + o.h - ny;
        } else if (z.includes("s")) {
            root.selH = Math.max(minSize, Math.min(o.h + dy, root.screen.height - o.y));
        }
    }

    function adjustReleased(x, y) {
        if (root.adjustMode === "redraw" && (root.selW < root.minSelSize || root.selH < root.minSelSize)) {
            root.dismiss(); // Clicked away -> cancel
            return;
        }
        if (root.adjustMode !== "") {
            root.clampSelection();
            // Persist the latest adjusted position & size
            root.rememberSelection();
        }
        root.adjustMode = "";
        root.resizeZone = "";
    }

    // Execution after selection
    function snip() {
        // Validity check
        if (root.selW <= 0 || root.selH <= 0) {
            console.warn("[Region Selector] Invalid region size, skipping snip.");
            root.dismiss();
            return;
        }

        // Clamp region to screen bounds
        root.clampSelection();

        const screenshotDir = Config.options.screenSnip.savePath !== "" ? //
            Config.options.screenSnip.savePath : "";
        var screenshotAction = root.getScreenshotAction();
        if (screenshotAction === undefined || screenshotAction === null) return; // Copy = 0, so a falsy check would break the default action
        const command = ScreenshotAction.getCommand(
            root.selX * root.monitorScale, //
            root.selY * root.monitorScale, //
            root.selW * root.monitorScale,// 
            root.selH * root.monitorScale, //
            root.screenshotPath, //
            screenshotAction, //
            screenshotDir
        )
        root.rememberSelection();
        Quickshell.execDetached(command);
        if (root.action == RegionSelection.SnipAction.Record || root.action == RegionSelection.SnipAction.RecordWithSound) {
            root.phase = RegionSelection.Phase.Post
            root.selectionMode = RegionSelection.SelectionMode.RectCorners
        } else {
            root.dismiss();
        }
    }

    // Only clickable in Selection & Adjust phases
    mask: Region {
        item: switch(root.phase) {
            case RegionSelection.Phase.Select: return mouseArea;
            case RegionSelection.Phase.Adjust: return mouseArea;
            case RegionSelection.Phase.Post: return null;
        }
    }

    ScreencopyView { // For freezing
        anchors.fill: parent
        live: false
        captureSource: root.screen
        visible: root.phase !== RegionSelection.Phase.Post
    }

    // Stable keyboard focus owner: Esc = cancel, Enter = capture (adjust phase)
    Item {
        id: keyHandler
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss();
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                && root.phase === RegionSelection.Phase.Adjust
                && GlobalStates.regionSelectorActiveScreen === root.screen.name) {
                root.snip();
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: {
            if (root.phase !== RegionSelection.Phase.Adjust) return Qt.CrossCursor;
            const zone = (root.adjustMode === "move") ? "move" : //
                (root.adjustMode === "" ? root.hoverZone : root.resizeZone);
            switch (zone) {
                case "nw": case "se": return Qt.SizeFDiagCursor;
                case "ne": case "sw": return Qt.SizeBDiagCursor;
                case "n": case "s": return Qt.SizeVerCursor;
                case "w": case "e": return Qt.SizeHorCursor;
                case "move": return Qt.SizeAllCursor;
                default: return Qt.CrossCursor;
            }
        }

        // Controls
        onPressed: (mouse) => {
            GlobalStates.regionSelectorActiveScreen = root.screen.name;
            if (root.phase === RegionSelection.Phase.Adjust) {
                if (mouse.button !== Qt.LeftButton) return;
                root.adjustPressed(mouse.x, mouse.y);
                return;
            }
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragging = true;
            root.mouseButton = mouse.button;
        }
        onReleased: (mouse) => {
            if (root.phase === RegionSelection.Phase.Adjust) {
                root.adjustReleased(mouse.x, mouse.y);
                return;
            }
            // Detect if it was a click -> Try to select targeted region
            if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                if (root.targetedRegionValid()) {
                    root.setRegionToTargeted();
                }
            }
            // Circle dragging?
            else if (root.selectionMode === RegionSelection.SelectionMode.Circle) {
                const padding = Config.options.regionSelector.circle.padding + Config.options.regionSelector.circle.strokeWidth / 2;
                const dragPoints = (root.points.length > 0) ? root.points : [{ x: mouseArea.mouseX, y: mouseArea.mouseY }];
                const maxX = Math.max(...dragPoints.map(p => p.x));
                const minX = Math.min(...dragPoints.map(p => p.x));
                const maxY = Math.max(...dragPoints.map(p => p.y));
                const minY = Math.min(...dragPoints.map(p => p.y));
                root.selX = minX - padding;
                root.selY = minY - padding;
                root.selW = maxX - minX + padding * 2;
                root.selH = maxY - minY + padding * 2;
            }
            root.finishSelection();
        }
        onPositionChanged: (mouse) => {
            if (root.phase === RegionSelection.Phase.Adjust) {
                root.adjustMoved(mouse.x, mouse.y);
                return;
            }
            root.updateTargetedRegion(mouse.x, mouse.y);
            if (!root.dragging) return;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.selX = Math.min(root.dragStartX, mouse.x);
            root.selY = Math.min(root.dragStartY, mouse.y);
            root.selW = Math.abs(mouse.x - root.dragStartX);
            root.selH = Math.abs(mouse.y - root.dragStartY);
            root.dragDiffX = mouse.x - root.dragStartX;
            root.dragDiffY = mouse.y - root.dragStartY;
            root.points.push({ x: mouse.x, y: mouse.y });
        }
        
        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.RectCorners
            sourceComponent: RectCornersSelectionDetails {
                regionX: root.selX
                regionY: root.selY
                regionWidth: root.selW
                regionHeight: root.selH
                mouseX: mouseArea.mouseX
                mouseY: mouseArea.mouseY
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                breathingBorderOnly: root.phase === RegionSelection.Phase.Post
            }
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.Circle
            sourceComponent: CircleSelectionDetails {
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                points: root.points
            }
        }

        // Resize handles (adjust phase)
        Item {
            z: 6
            visible: root.phase === RegionSelection.Phase.Adjust
            x: root.selX
            y: root.selY
            width: root.selW
            height: root.selH

            Repeater {
                model: [
                    { "xr": 0, "yr": 0 },
                    { "xr": 0.5, "yr": 0, "stretch": "h" },
                    { "xr": 1, "yr": 0 },
                    { "xr": 1, "yr": 0.5, "stretch": "v" },
                    { "xr": 1, "yr": 1 },
                    { "xr": 0.5, "yr": 1, "stretch": "h" },
                    { "xr": 0, "yr": 1 },
                    { "xr": 0, "yr": 0.5, "stretch": "v" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool corner: modelData.stretch === undefined
                    readonly property int cornerSize: 10
                    radius: corner ? 2 : 1
                    color: root.brightText
                    border.width: 1
                    border.color: root.onBorderColor
                    width: corner ? cornerSize : (modelData.stretch === "h"
                        ? Math.max(6, Math.min(parent.width - cornerSize * 2, 28))
                        : 4)
                    height: corner ? cornerSize : (modelData.stretch === "v"
                        ? Math.max(6, Math.min(parent.height - cornerSize * 2, 28))
                        : 4)
                    x: Math.round(modelData.xr * parent.width - width / 2)
                    y: Math.round(modelData.yr * parent.height - height / 2)
                }
            }
        }

        // The thing to the bottom-right with an icon
        CursorGuide {
            z: 9999
            visible: root.phase === RegionSelection.Phase.Select
            x: root.dragging ? root.selX + root.selW : mouseArea.mouseX
            y: root.dragging ? root.selY + root.selH : mouseArea.mouseY
            action: root.action
            selectionMode: root.selectionMode
        }

        // Window regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableWindowRegions) {
                        return root.windowRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 2
                required property var modelData
                clientDimensions: modelData
                showIcon: true
                targeted: !root.draggedAway && //
                    (root.targetedRegionX === modelData.at[0]  //
                    && root.targetedRegionY === modelData.at[1] //
                    && root.targetedRegionWidth === modelData.size[0] //
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                text: `${modelData.class}`
                radius: Appearance.rounding.windowRounding
            }
        }

        // Layer regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableLayerRegions) {
                        return root.layerRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 3
                required property var modelData
                clientDimensions: modelData
                targeted: !root.draggedAway &&
                    (root.targetedRegionX === modelData.at[0] 
                    && root.targetedRegionY === modelData.at[1]
                    && root.targetedRegionWidth === modelData.size[0]
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                text: `${modelData.namespace}`
                radius: Appearance.rounding.windowRounding
            }
        }

        // Content regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableContentRegions) {
                        return root.imageRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 4
                required property var modelData
                clientDimensions: modelData
                targeted: !root.draggedAway &&
                    (root.targetedRegionX === modelData.at[0] 
                    && root.targetedRegionY === modelData.at[1]
                    && root.targetedRegionWidth === modelData.size[0]
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.contentRegionOpacity
                borderColor: root.imageBorderColor
                fillColor: targeted ? root.imageFillColor : "transparent"
                text: Translation.tr("Content region")
            }
        }

        // Controls
        Row {
            id: regionSelectionControls
            z: 10
            visible: root.phase === RegionSelection.Phase.Select || root.phase === RegionSelection.Phase.Adjust
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: -height
            }
            opacity: 0
            Connections {
                target: root
                function onVisibleChanged() {
                    if (!visible) return;
                    regionSelectionControls.anchors.bottomMargin = 8;
                    regionSelectionControls.opacity = 1;
                }
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on anchors.bottomMargin {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            spacing: 6

            OptionsToolbar {
                Synchronizer on action {
                    property alias source: root.action
                }
                Synchronizer on selectionMode {
                    property alias source: root.selectionMode
                }
                onDismiss: root.dismiss();
            }
            ToolbarPairedFab {
                anchors.verticalCenter: parent.verticalCenter
                iconText: "check"
                visible: root.phase === RegionSelection.Phase.Adjust
                onClicked: {
                    GlobalStates.regionSelectorActiveScreen = root.screen.name;
                    root.snip();
                }
                StyledToolTip {
                    text: Translation.tr("Capture")
                }
            }
            ToolbarPairedFab {
                anchors.verticalCenter: parent.verticalCenter
                iconText: "close"
                onClicked: root.dismiss();
                StyledToolTip {
                    text: Translation.tr("Close")
                }
            }
        }
        
    }
}
