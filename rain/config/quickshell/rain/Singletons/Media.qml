pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MPRIS media player state, aggregated from all running players.
// provides a single player (the most recent active one) and playback state.
QtObject {
    id: media

    readonly property var players: Mpris.players
    readonly property var player: {
        var active = null;
        var last = null;
        for (var i = 0; i < players.length; i++) {
            var p = players[i];
            if (!p) continue;
            last = p;
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        }
        return last;
    }

    readonly property bool present: player !== null
    readonly property bool playing: player ? player.playbackState === MprisPlaybackState.Playing : false

    readonly property string line: {
        if (!player) return "";
        var t = player.trackTitle || "";
        var a = player.trackArtists || player.trackArtist || "";
        var sep = t.length > 0 && a.length > 0 ? " — " : "";
        return t + sep + a;
    }

    function toggle() {
        if (player) player.playPause();
    }
}
