import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons

Item {
  id: root

  property var shell: null
  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string cosmosCtl: home + "/.local/bin/cosmos-ctl"

  property bool drawerOpen: false
  property var cosmosConfig: ({
    barStyle: "frame",
    menuStyle: "left",
    pinLayout: "left",
    rainMode: "drizzle",
    showWallpaperLogo: true,
    logoStyle: "warm",
    logoScale: "medium",
    arrivalOnUnlock: true,
    activeAppearance: "last-horizon",
    undoPending: false
  })
  property var appearancesList: []
  property bool introsEnabled: true
  property string currentThemeName: "last-horizon"

  function reloadAll() {
    cfgFile.reload()
    if (!appearancesProc.running) appearancesProc.running = true
  }

  function runCtl(args) {
    Quickshell.execDetached([root.cosmosCtl].concat(args))
  }

  function openThemeStudio() {
    root.drawerOpen = false
    Quickshell.execDetached(["omarchy-shell", "shell", "toggle", "io.github.denonmaryland.theme-studio"])
  }

  FileView {
    id: cfgFile
    path: root.stateHome + "/cosmos/config.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(String(cfgFile.text() || "{}"))
        if (parsed && typeof parsed === "object") {
          root.cosmosConfig = parsed
        }
      } catch (e) {}
    }
    onFileChanged: {
      cfgFile.reload()
      if (!appearancesProc.running) appearancesProc.running = true
    }
  }

  Process {
    id: appearancesProc
    command: [root.cosmosCtl, "appearance", "list"]
    stdout: StdioCollector {
      id: appOut
      onStreamFinished: {
        try {
          var data = JSON.parse(String(appOut.text || "{}"))
          if (Array.isArray(data.appearances)) root.appearancesList = data.appearances
          root.introsEnabled = data.introsEnabled !== false
          if (data.currentTheme) root.currentThemeName = String(data.currentTheme)
        } catch (e) {}
      }
    }
  }

  ShellIpc {
    target: "cosmos.settings"

    function toggle(): void {
      root.drawerOpen = !root.drawerOpen
      if (root.drawerOpen) root.reloadAll()
    }

    function open(): void {
      root.drawerOpen = true
      root.reloadAll()
    }

    function close(): void {
      root.drawerOpen = false
    }

    function syncConfig(): void {
      root.reloadAll()
    }
  }

  Component.onCompleted: reloadAll()

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: overlayWin
      required property var modelData

      screen: modelData
      visible: root.drawerOpen || slideOutHold.running
      color: "transparent"
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "cosmos-settings"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.drawerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

      Timer {
        id: slideOutHold
        interval: 220
        repeat: false
      }

      Connections {
        target: root
        function onDrawerOpenChanged() {
          if (!root.drawerOpen) slideOutHold.restart()
          else drawerCard.forceActiveFocus()
        }
      }

      // Click outside drawer closes cleanly
      MouseArea {
        anchors.fill: parent
        onClicked: root.drawerOpen = false
      }

      SettingsDrawer {
        id: drawerCard
        width: 416
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 48
        anchors.bottomMargin: 12
        anchors.rightMargin: 12

        cosmosConfig: root.cosmosConfig
        appearancesList: root.appearancesList
        introsEnabled: root.introsEnabled
        currentThemeName: root.currentThemeName

        transform: Translate {
          x: root.drawerOpen ? 0 : 440
          Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
          }
        }

        opacity: root.drawerOpen ? 1.0 : 0.0
        Behavior on opacity {
          NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
        }

        onRunCtlRequested: function(args) { root.runCtl(args) }
        onCloseRequested: root.drawerOpen = false
        onOpenThemeStudioRequested: root.openThemeStudio()
      }
    }
  }
}
