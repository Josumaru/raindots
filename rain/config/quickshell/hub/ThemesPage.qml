pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "Singletons"

// themes: full-system "rices" as a bento grid. picking one swaps the look
// via `rain hub hypr theme <slug>`.
Item {
    id: page

    property var themes: []
    property bool followWallpaper: true
    property bool loading: true
    property string applying: ""

    readonly property int cols: width >= 1100 ? 3 : (width >= 720 ? 2 : 1)

    implicitWidth: 600
    implicitHeight: col.implicitHeight

    Component.onCompleted: page.reload()
    function reload() { listProc.running = true; }
    function apply(slug) {
        page.applying = slug;
        applyProc.command = [Directories.rainBin, "hub", "hypr", "theme", slug];
        applyProc.running = true;
    }
    function setFollow(on) {
        page.followWallpaper = on;
        Quickshell.execDetached([Directories.rainBin, "hub", "hypr", "scheme", on ? "follow" : "dark"]);
    }

    function buildColumns(list, n) {
        var c = [], h = [], i;
        for (i = 0; i < n; i++) { c.push([]); h.push(0); }
        for (i = 0; i < list.length; i++) {
            var est = 170 + Math.ceil(((list[i].blurb || "").length) / 30) * 16;
            var min = 0;
            for (var j = 1; j < n; j++)
                if (h[j] < h[min]) min = j;
            c[min].push(list[i]);
            h[min] += est + 14;
        }
        return c;
    }
    readonly property var grouped: buildColumns(page.themes, page.cols)

    Process {
        id: listProc
        command: [Directories.rainBin, "hub", "hypr", "themes"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var o = JSON.parse(this.text);
                    var ts = o.themes || [];
                    for (var i = 0; i < ts.length; i++) ts[i].ordinal = i + 1;
                    page.themes = ts;
                    page.followWallpaper = !!o.followWallpaper;
                } catch (e) { page.themes = []; }
                page.loading = false;
            }
        }
    }
    Process {
        id: applyProc
        stdout: StdioCollector { onStreamFinished: { page.applying = ""; listProc.running = true; } }
    }

    Column {
        id: col
        width: page.width
        spacing: 16

        // colour-source toggle
        Rectangle {
            width: parent.width; height: 64
            radius: Theme.radius; color: Theme.surfaceLo
            border.width: 1; border.color: Theme.line

            Column {
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.right: sw.left; anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "Colours follow wallpaper"
                    color: Theme.bright; font.family: Theme.font
                    font.pixelSize: 14; font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: page.followWallpaper
                        ? "Themes change the look; colours come from your wallpaper."
                        : "Each theme uses its own palette; the wallpaper won't change colours."
                    color: Theme.dim; font.family: Theme.font; font.pixelSize: 12
                }
            }

            Rectangle {
                id: sw
                anchors.right: parent.right; anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: 46; height: 26; radius: Theme.radius
                color: page.followWallpaper ? Theme.ember : Theme.keyTop
                border.width: 1; border.color: page.followWallpaper ? Theme.ember : Theme.line
                Behavior on color { ColorAnimation { duration: Theme.quick } }

                Rectangle {
                    width: 20; height: 20; radius: 10; y: 3
                    x: page.followWallpaper ? parent.width - width - 3 : 3
                    color: page.followWallpaper ? Theme.onAccent : Theme.dim
                    Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Theme.ease } }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: page.setFollow(!page.followWallpaper) }
            }
        }

        Text {
            visible: page.loading
            text: "Loading themes…"
            color: Theme.dim; font.family: Theme.font; font.pixelSize: 14
        }

        Row {
            id: masonry
            width: parent.width; spacing: 14
            visible: !page.loading

            Repeater {
                model: page.cols
                delegate: Column {
                    id: column
                    required property int index
                    width: (masonry.width - (page.cols - 1) * 14) / page.cols
                    spacing: 14

                    Repeater {
                        model: page.grouped[column.index] || []
                        delegate: ThemeTile {
                            required property var modelData
                            width: column.width
                            theme: modelData
                            ordinal: modelData.ordinal || 0
                            active: !!modelData.active
                            busy: page.applying === modelData.slug
                            onApplied: page.apply(modelData.slug)
                        }
                    }
                }
            }
        }
    }
}
