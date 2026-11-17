import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")

  // Cosmos Config State (~/.local/state/cosmos/config.json)
  property bool studioOpen: true
  property string pinLayout: "left"
  property string playerMode: "vinyl"

  // Live Agents State (~/.local/state/cosmos/agents-live.json)
  property int needsYouCount: 0
  property int workingCount: 0
  property int finishedCount: 0
  property int totalCount: 0
  property string headlineStatus: "idle"
  property string headlineLabel: "Ready"
  property string urgentAgentName: ""
  property string urgentTitle: "Cosmos Studio"
  property string urgentWindowAddress: ""
  property var crewList: []

  // Live MPRIS Media State (YouTube Music / Browser / Player)
  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: {
    var list = root.players
    if (!list || list.length === 0) return null
    var fallback = null
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      if (!p) continue
      var ident = String(p.identity || p.desktopEntry || "").toLowerCase()
      if (ident.indexOf("playerctld") !== -1) continue
      if (p.playbackState === MprisPlaybackState.Playing) return p
      if (!fallback && (p.trackTitle || p.trackArtist)) fallback = p
    }
    return fallback || list[0]
  }

  readonly property bool hasMedia: activePlayer !== null && !!(activePlayer.trackTitle || activePlayer.trackArtist)
  readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing
  readonly property string trackTitle: activePlayer ? String(activePlayer.trackTitle || "") : ""
  readonly property string trackArtist: activePlayer ? String(activePlayer.trackArtist || "") : ""
  readonly property string artUrl: activePlayer && activePlayer.trackArtUrl ? String(activePlayer.trackArtUrl) : ""

  property int posTick: 0
  readonly property real positionSec: {
    var _tick = root.posTick
    if (!activePlayer) return 0
    var pos = Number(activePlayer.position || 0)
    return isFinite(pos) && pos > 0 ? pos : 0
  }
  readonly property real lengthSec: {
    var _tick = root.posTick
    if (!activePlayer) return 0
    var len = Number(activePlayer.length || 0)
    return isFinite(len) && len > 0 ? len : 0
  }
  readonly property real progress: lengthSec > 0.5 ? Math.max(0.0, Math.min(1.0, positionSec / lengthSec)) : 0.0
  readonly property string formattedPosition: formatSeconds(positionSec)
  readonly property string formattedLength: formatSeconds(lengthSec)

  function formatSeconds(sec) {
    var total = Math.max(0, Math.floor(Number(sec || 0)))
    var m = Math.floor(total / 60)
    var s = total % 60
    return m + ":" + (s < 10 ? "0" + s : String(s))
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.isPlaying
    onTriggered: {
      if (root.activePlayer && typeof root.activePlayer.positionChanged === "function") {
        try { root.activePlayer.positionChanged() } catch (e) {}
      }
      root.posTick = (root.posTick + 1) % 100000
    }
  }

  function togglePlay() {
    if (activePlayer) {
      if (activePlayer.canTogglePlaying) activePlayer.togglePlaying()
      else if (isPlaying && activePlayer.canPause) activePlayer.pause()
      else if (!isPlaying && activePlayer.canPlay) activePlayer.play()
    } else {
      openMusicDrawer()
    }
  }

  function prevTrack() {
    if (activePlayer && activePlayer.canGoPrevious) activePlayer.previous()
  }

  function nextTrack() {
    if (activePlayer && activePlayer.canGoNext) activePlayer.next()
  }

  function seekToRatio(ratio) {
    if (!activePlayer || lengthSec <= 0.5) return
    var clamped = Math.max(0.0, Math.min(1.0, Number(ratio || 0)))
    var targetSec = clamped * lengthSec
    try {
      if (activePlayer.canSeek && activePlayer.positionSupported) {
        activePlayer.position = targetSec
        root.posTick = (root.posTick + 1) % 100000
      }
    } catch (e) {
    }
  }

  function openMusicDrawer() {
    Quickshell.execDetached([root.home + "/.local/bin/cosmos-ctl", "music-open"])
  }

  function focusMostUrgentAgent() {
    if (urgentWindowAddress) {
      Quickshell.execDetached([root.home + "/.local/bin/cosmos-ctl", "focus-agent", urgentWindowAddress])
    } else {
      Quickshell.execDetached([root.home + "/.local/bin/cosmos-ctl", "studio", "toggle"])
    }
  }

  function focusAgentAddress(addr) {
    if (!addr) return
    Quickshell.execDetached([root.home + "/.local/bin/cosmos-ctl", "focus-agent", String(addr)])
  }

  function parseConfig(raw) {
    var text = String(raw || "").trim()
    if (!text) return
    try {
      var parsed = JSON.parse(text)
      if (!parsed || typeof parsed !== "object") return
      if ("studioOpen" in parsed) studioOpen = parsed.studioOpen !== false
      var pl = String(parsed.pinLayout || "left")
      if (["left", "center", "right"].indexOf(pl) !== -1) pinLayout = pl
      var pm = String(parsed.playerMode || "vinyl")
      if (["vinyl", "aurora", "minimal"].indexOf(pm) !== -1) playerMode = pm
    } catch (e) {
    }
  }

  function parseAgents(raw) {
    var text = String(raw || "").trim()
    if (!text) return
    try {
      var data = JSON.parse(text)
      if (!data || typeof data !== "object") return
      needsYouCount = Number(data.needsYouCount || 0)
      workingCount = Number(data.workingCount || 0)
      finishedCount = Number(data.finishedCount || 0)
      totalCount = Number(data.totalCount || 0)
      headlineStatus = String(data.headlineStatus || "idle")
      headlineLabel = String(data.headlineLabel || "Ready")
      if (data.mostUrgent && typeof data.mostUrgent === "object") {
        urgentAgentName = String(data.mostUrgent.agentName || "")
        urgentTitle = String(data.mostUrgent.title || "Agent task")
        urgentWindowAddress = String(data.mostUrgent.windowAddress || "")
      } else {
        urgentAgentName = ""
        urgentTitle = "Cosmos Studio"
        urgentWindowAddress = ""
      }
      crewList = Array.isArray(data.crew) ? data.crew : []
    } catch (e) {
    }
  }

  FileView {
    id: configFile
    path: root.stateHome + "/cosmos/config.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.parseConfig(text())
    onFileChanged: reload()
  }

  FileView {
    id: agentsFile
    path: root.stateHome + "/cosmos/agents-live.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.parseAgents(text())
    onFileChanged: reload()
  }

  // Managed background watcher process — starts with omarchy-shell and exits cleanly when unloaded!
  Process {
    id: agentWatcherDaemon
    running: true
    command: [root.home + "/.local/bin/cosmos-agent-watcher"]
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event ? String(event.name) : ""
      if (
        name === "openwindow"
        || name === "closewindow"
        || name === "movewindow"
        || name === "movewindowv2"
        || name === "workspace"
        || name === "workspacev2"
        || name === "fullscreen"
      ) {
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
      }
    }
  }

  ShellIpc {
    target: "cosmos.studio"

    function syncConfig(): void {
      configFile.reload()
    }

    function syncAgents(): void {
      agentsFile.reload()
    }

    function toggle(): void {
      Quickshell.execDetached([root.home + "/.local/bin/cosmos-ctl", "studio", "toggle"])
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      DesktopPinsWindow {
        required property var modelData
        screen: modelData
        studio: root
      }
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      StudioSidePanel {
        required property var modelData
        screen: modelData
        studio: root
      }
    }
  }
}
