import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Commons as Commons

PanelWindow {
  id: sideWindow

  property var studio: null
  property bool crewExpanded: false
  property real shaderTime: 0.0
  property bool readyToMap: false

  Timer {
    interval: 300
    running: true
    repeat: false
    onTriggered: sideWindow.readyToMap = true
  }

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property var workspace: monitor ? monitor.activeWorkspace : null
  readonly property int workspaceId: workspace ? workspace.id : -1

  readonly property int windowCount: {
    if (workspaceId < 1) return 0
    var count = 0
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var tl = toplevels[i]
      if (tl.workspace && tl.workspace.id === workspaceId) {
        count += 1
      }
    }
    return count
  }

  readonly property int fullscreenMode: {
    if (workspaceId < 1) return 0
    var mode = 0
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var tl = toplevels[i]
      if (!tl.workspace || tl.workspace.id !== workspaceId) continue
      var ipc = tl.lastIpcObject
      mode = Math.max(mode, ipc && ipc.fullscreen ? ipc.fullscreen : 0)
    }
    return mode
  }

  readonly property int cardWidth: Style.space(340)
  readonly property int outerGap: Style.space(12)
  readonly property bool panelShown: !!studio && studio.studioOpen && windowCount > 0 && fullscreenMode < 2

  readonly property color amberColor: "#f0a843"
  readonly property color creamColor: "#e8dcc2"
  readonly property color greenColor: "#4ade80"
  readonly property string playerMode: studio ? studio.playerMode : "vinyl"

  implicitWidth: cardWidth + outerGap
  visible: readyToMap
  color: "transparent"
  surfaceFormat.opaque: false
  WlrLayershell.namespace: "cosmos-studio"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: panelShown ? ExclusionMode.Normal : ExclusionMode.Ignore
  exclusiveZone: panelShown ? (cardWidth + outerGap) : 0

  anchors {
    top: true
    bottom: true
    right: true
    left: false
  }

  mask: panelShown ? studioMask : emptyStudioMask

  Region {
    id: studioMask
    item: studioCard
  }

  Region {
    id: emptyStudioMask
    item: emptyStudioBox
  }

  Item {
    id: emptyStudioBox
    width: 0
    height: 0
  }

  Timer {
    interval: 33
    repeat: true
    running: sideWindow.panelShown && sideWindow.playerMode === "aurora"
    onTriggered: sideWindow.shaderTime += 0.033
  }

  // Main Cosmos Studio Docked Card
  ClippingRectangle {
    id: studioCard
    x: sideWindow.panelShown ? 0 : (sideWindow.cardWidth + sideWindow.outerGap)
    y: Style.space(6)
    width: sideWindow.cardWidth
    height: Math.max(Style.space(400), parent.height - Style.space(18))
    radius: Style.space(18)
    color: {
      var bg = Commons.Color.background
      return Qt.rgba(bg.r * 0.65 + 0.04, bg.g * 0.65 + 0.04, bg.b * 0.65 + 0.045, 0.96)
    }

    opacity: sideWindow.panelShown ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // ---------------------------------------------------------
    // 1. TOP HALF: Original Cosmos Observatory Scene + Badges
    // ---------------------------------------------------------
    Item {
      id: loftArea
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: Math.min(Style.space(430), Math.round(studioCard.height * 0.48))

      // Smooth vertical vignette into dark player deck below (sits below robot nameplates)
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Style.space(112)
        gradient: Gradient {
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 0.58; color: Qt.rgba(studioCard.color.r, studioCard.color.g, studioCard.color.b, 0.72) }
          GradientStop { position: 1.0; color: studioCard.color }
        }
      }

      StudioScene {
        anchors.fill: parent
        compact: false
        active: sideWindow.panelShown
        totalCount: sideWindow.studio ? sideWindow.studio.totalCount : 0
        needsYouCount: sideWindow.studio ? sideWindow.studio.needsYouCount : 0
        workingCount: sideWindow.studio ? sideWindow.studio.workingCount : 0
        finishedCount: sideWindow.studio ? sideWindow.studio.finishedCount : 0
        crewList: sideWindow.studio ? sideWindow.studio.crewList : []
        accentColor: Commons.Color.accent
        onAgentClicked: function(addr) {
          if (sideWindow.studio && addr) {
            sideWindow.studio.focusAgentAddress(addr)
          }
        }
      }

      // Re-apply subtle bottom-most fade right under agentCard
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Style.space(98)
        gradient: Gradient {
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 0.65; color: Qt.rgba(studioCard.color.r, studioCard.color.g, studioCard.color.b, 0.88) }
          GradientStop { position: 1.0; color: studioCard.color }
        }
      }

      // Top-left active agent count capsule (like current-studio.png)
      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Style.space(12)
        height: Style.space(24)
        width: countBadgeRow.implicitWidth + Style.space(14)
        radius: height / 2
        color: Qt.rgba(0.08, 0.09, 0.11, 0.76)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)

        Row {
          id: countBadgeRow
          anchors.centerIn: parent
          spacing: Style.space(5)

          Text {
            textFormat: Text.PlainText
            text: "󰚩"
            font.family: Style.font.family
            font.pixelSize: Style.space(12)
            color: sideWindow.creamColor
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            textFormat: Text.PlainText
            text: String(sideWindow.studio ? sideWindow.studio.totalCount : 0)
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      // Top-right collapse button (OPT+D)
      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.space(12)
        width: Style.space(24)
        height: Style.space(24)
        radius: width / 2
        color: closeHover.containsMouse ? Qt.rgba(0.16, 0.17, 0.20, 0.90) : Qt.rgba(0.08, 0.09, 0.11, 0.72)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: "›"
          font.family: Style.font.family
          font.pixelSize: Style.space(14)
          font.bold: true
          color: "#e6e8ee"
        }

        MouseArea {
          id: closeHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/cosmos-ctl", "studio", "close"])
        }
      }
    }

    // ---------------------------------------------------------
    // 2. FLOATING TASK & CREW CARD (overlapping the loft desk)
    // ---------------------------------------------------------
    Rectangle {
      id: agentCard
      z: 3
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: Style.space(14)
      anchors.rightMargin: Style.space(14)
      y: loftArea.height - Style.space(102)
      height: agentCardCol.implicitHeight + Style.space(24)
      radius: Style.space(14)
      color: Qt.rgba(0.09, 0.10, 0.13, 0.92)
      border.width: 1
      border.color: (sideWindow.studio && sideWindow.studio.needsYouCount > 0)
        ? Qt.rgba(sideWindow.amberColor.r, sideWindow.amberColor.g, sideWindow.amberColor.b, 0.50)
        : Qt.rgba(1, 1, 1, 0.14)

      Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Column {
        id: agentCardCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.space(12)
        spacing: Style.space(8)

        // Status header row
        Item {
          width: parent.width
          height: Style.space(18)

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Rectangle {
              width: Style.space(13)
              height: Style.space(13)
              radius: (sideWindow.studio && sideWindow.studio.needsYouCount > 0) ? 3 : (width / 2)
              anchors.verticalCenter: parent.verticalCenter
              color: {
                if (!sideWindow.studio) return "transparent"
                if (sideWindow.studio.needsYouCount > 0) return sideWindow.amberColor
                if (sideWindow.studio.workingCount > 0) return "transparent"
                if (sideWindow.studio.finishedCount > 0) return sideWindow.greenColor
                return Qt.rgba(1, 1, 1, 0.28)
              }
              border.width: (sideWindow.studio && sideWindow.studio.needsYouCount === 0 && sideWindow.studio.workingCount > 0) ? 1.8 : 0
              border.color: Commons.Color.accent

              Text {
                visible: !!sideWindow.studio && (sideWindow.studio.needsYouCount > 0 || (sideWindow.studio.workingCount === 0 && sideWindow.studio.finishedCount > 0))
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: (sideWindow.studio && sideWindow.studio.needsYouCount > 0) ? "?" : "✓"
                font.family: Style.font.family
                font.pixelSize: Style.space(9)
                font.bold: true
                color: "#111215"
              }
            }

            Text {
              textFormat: Text.PlainText
              text: sideWindow.studio ? sideWindow.studio.headlineLabel : "Ready"
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              color: {
                if (sideWindow.studio && sideWindow.studio.needsYouCount > 0) return sideWindow.amberColor
                if (sideWindow.studio && sideWindow.studio.workingCount > 0) return "#f0f2f7"
                if (sideWindow.studio && sideWindow.studio.finishedCount > 0) return sideWindow.greenColor
                return "#b5bac6"
              }
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(Style.space(80), parent.width * 0.54)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: {
              if (!sideWindow.studio || sideWindow.studio.totalCount === 0) return "Antigravity · ChatGPT · Claude · Codex"
              var name = sideWindow.studio.urgentAgentName || "Agent"
              var tot = sideWindow.studio.totalCount
              return tot > 1 ? (name + " · most urgent of " + tot) : name
            }
            font.family: Style.font.family
            font.pixelSize: Style.space(11)
            color: "#8f96a6"
          }
        }

        // Bold Task Title
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: (sideWindow.studio && sideWindow.studio.totalCount > 0) ? sideWindow.studio.urgentTitle : "Waiting for agent session"
          font.family: Style.font.family
          font.pixelSize: Style.space(17)
          font.bold: true
          color: "#f5f7fb"
          elide: Text.ElideRight
        }

        // Action Buttons Row: "Respond ↗" / "Open task ↗" + "Crew N ›"
        Row {
          width: parent.width
          spacing: Style.space(8)

          // Primary CTA Button
          Rectangle {
            readonly property bool isUrgent: !!sideWindow.studio && sideWindow.studio.needsYouCount > 0
            width: Math.floor((parent.width - Style.space(8)) * 0.52)
            height: Style.space(34)
            radius: Style.space(9)
            color: {
              var base = isUrgent ? sideWindow.amberColor : sideWindow.creamColor
              return primaryMouse.containsMouse ? Qt.lighter(base, 1.08) : base
            }

            Item {
              anchors.fill: parent
              anchors.leftMargin: Style.space(11)
              anchors.rightMargin: Style.space(11)

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: (sideWindow.studio && sideWindow.studio.needsYouCount > 0) ? "Respond" : "Open task"
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                color: "#151412"
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: "↗"
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                color: "#151412"
              }
            }

            MouseArea {
              id: primaryMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (sideWindow.studio) sideWindow.studio.focusMostUrgentAgent()
            }
          }

          // Secondary Crew Button
          Rectangle {
            width: Math.floor((parent.width - Style.space(8)) * 0.48)
            height: Style.space(34)
            radius: Style.space(9)
            color: crewMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.16)

            Item {
              anchors.fill: parent
              anchors.leftMargin: Style.space(11)
              anchors.rightMargin: Style.space(11)

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: "Crew"
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                color: "#eef0f6"
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: {
                  var n = sideWindow.studio ? sideWindow.studio.totalCount : 0
                  return (n > 0 ? (n + " ") : "") + (sideWindow.crewExpanded ? "⌄" : "›")
                }
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                color: "#a5acb8"
              }
            }

            MouseArea {
              id: crewMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: sideWindow.crewExpanded = !sideWindow.crewExpanded
            }
          }
        }

        // Expandable Crew List (Antigravity, Claude Code, Codex)
        Column {
          visible: sideWindow.crewExpanded
          width: parent.width
          spacing: Style.space(6)

          Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.10)
          }

          Repeater {
            model: sideWindow.studio ? sideWindow.studio.crewList : []
            delegate: Rectangle {
              required property var modelData
              width: agentCardCol.width
              height: Style.space(30)
              radius: Style.space(7)
              color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

              Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(6)
                anchors.right: jumpArrow.left
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(7)

                Rectangle {
                  width: Style.space(8)
                  height: Style.space(8)
                  radius: width / 2
                  anchors.verticalCenter: parent.verticalCenter
                  color: {
                    var st = String(modelData.status || "")
                    if (st === "needs_you") return sideWindow.amberColor
                    if (st === "working") return Commons.Color.accent
                    return sideWindow.greenColor
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  text: String(modelData.agentName || "Agent")
                  font.family: Style.font.family
                  font.pixelSize: Style.space(11)
                  font.bold: true
                  color: "#e6e9f2"
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  width: Math.max(Style.space(40), parent.width - Style.space(95))
                  textFormat: Text.PlainText
                  text: String(modelData.title || "")
                  font.family: Style.font.family
                  font.pixelSize: Style.space(11)
                  color: "#99a0ae"
                  elide: Text.ElideRight
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Text {
                id: jumpArrow
                anchors.right: parent.right
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: "↗"
                font.family: Style.font.family
                font.pixelSize: Style.space(11)
                color: "#99a0ae"
              }

              MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (sideWindow.studio && modelData.windowAddress) {
                    sideWindow.studio.focusAgentAddress(String(modelData.windowAddress))
                  }
                }
              }
            }
          }

          Text {
            visible: !sideWindow.studio || sideWindow.studio.totalCount === 0
            textFormat: Text.PlainText
            text: "Abre Antigravity, ChatGPT, `claude` o `codex` para verlos aquí."
            font.family: Style.font.family
            font.pixelSize: Style.space(11)
            color: "#8e95a4"
            wrapMode: Text.WordWrap
            width: parent.width
          }
        }
      }
    }

    // ---------------------------------------------------------
    // 3. BOTTOM HALF: Vinyl / Aurora / Minimal YouTube Music Deck
    // ---------------------------------------------------------
    Item {
      id: playerDeck
      anchors.top: loftArea.bottom
      anchors.topMargin: Style.space(26)
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom

      // Real-time 60fps GLSL Aurora Fluid Visualizer background when playerMode === "aurora"
      ShaderEffect {
        id: auroraShader
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: sideWindow.playerMode === "aurora" ? 1.0 : 0.0
        fragmentShader: Qt.resolvedUrl("shaders/aurora.frag.qsb")

        property real uTime: sideWindow.shaderTime
        property real uEnergy: (sideWindow.studio && sideWindow.studio.isPlaying) ? 1.0 : 0.22
        property vector4d uColorA: Qt.vector4d(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 1.0)
        property vector4d uColorB: Qt.vector4d(
          Commons.Color.foreground.r * 0.55 + 0.15,
          Commons.Color.foreground.g * 0.60 + 0.18,
          Commons.Color.foreground.b * 0.65 + 0.20,
          1.0
        )
        property vector4d uBg: Qt.vector4d(studioCard.color.r, studioCard.color.g, studioCard.color.b, 1.0)

        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      }

      // Visual Stage (Vinyl Turntable OR Minimal Artwork; clear window for Aurora!)
      Item {
        id: visualStage
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlsColumn.top
        anchors.bottomMargin: Style.space(6)

        VinylDiscView {
          anchors.centerIn: parent
          discSize: Math.max(Style.space(128), Math.min(Style.space(204), visualStage.height - Style.space(8)))
          visible: opacity > 0.01
          opacity: sideWindow.playerMode === "vinyl" ? 1.0 : 0.0
          artUrl: sideWindow.studio ? sideWindow.studio.artUrl : ""
          playing: sideWindow.studio ? sideWindow.studio.isPlaying : false
          progress: sideWindow.studio ? sideWindow.studio.progress : 0.0
          accentColor: Commons.Color.accent
          onClicked: if (sideWindow.studio) sideWindow.studio.togglePlay()

          Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }

        // Minimal mode rounded album card (dot 3)
        ClippingRectangle {
          anchors.centerIn: parent
          width: Math.min(Style.space(132), visualStage.height - Style.space(16))
          height: width
          radius: Style.space(18)
          visible: opacity > 0.01
          opacity: sideWindow.playerMode === "minimal" ? 1.0 : 0.0
          color: "#171920"

          Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

          Image {
            anchors.fill: parent
            source: sideWindow.studio ? sideWindow.studio.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            visible: source !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: !sideWindow.studio || sideWindow.studio.artUrl === ""
            textFormat: Text.PlainText
            text: "󰀥"
            font.family: Style.font.family
            font.pixelSize: Style.space(38)
            color: Commons.Color.accent
          }
        }
      }

      // Bottom Track Info, Mode Dots, Seek Bar & Transport
      Column {
        id: controlsColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Style.space(20)
        anchors.rightMargin: Style.space(20)
        anchors.bottomMargin: Style.space(18)
        spacing: Style.space(11)

        // Mode switcher dots (Vinyl · Aurora · Minimal) + YT Music drawer chevron
        Item {
          width: parent.width
          height: Style.space(18)

          Row {
            anchors.centerIn: parent
            spacing: Style.space(8)

            Repeater {
              model: ["vinyl", "aurora", "minimal"]
              delegate: Rectangle {
                required property string modelData
                readonly property bool isCurrent: sideWindow.playerMode === modelData
                width: isCurrent ? Style.space(16) : Style.space(5)
                height: Style.space(5)
                radius: height / 2
                color: isCurrent ? sideWindow.creamColor : Qt.rgba(1, 1, 1, 0.26)
                anchors.verticalCenter: parent.verticalCenter

                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 180 } }

                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -Style.space(5)
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/cosmos-ctl", "player-mode", modelData])
                }
              }
            }
          }

          // Subtle right chevron to pop open/hide YouTube Music window
          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: "⌃"
            font.family: Style.font.family
            font.pixelSize: Style.space(14)
            color: Qt.rgba(1, 1, 1, 0.52)

            MouseArea {
              anchors.fill: parent
              anchors.margins: -Style.space(6)
              cursorShape: Qt.PointingHandCursor
              onClicked: if (sideWindow.studio) sideWindow.studio.openMusicDrawer()
            }
          }
        }

        // Song Title + YouTube Music Badge + Artist
        Column {
          width: parent.width
          spacing: Style.space(3)

          Item {
            width: parent.width
            height: Style.space(24)

            Text {
              anchors.left: parent.left
              anchors.right: ytmBadge.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
              text: (sideWindow.studio && sideWindow.studio.hasMedia) ? sideWindow.studio.trackTitle : "YouTube Music"
              font.family: Style.font.family
              font.pixelSize: Style.space(17)
              font.bold: true
              color: "#f5f7fb"
              elide: Text.ElideRight
            }

            // YouTube Music circular icon button (replaces Spotify logo!)
            Rectangle {
              id: ytmBadge
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(20)
              height: Style.space(20)
              radius: width / 2
              color: ytmHover.containsMouse ? "#ff2c2c" : Qt.rgba(1, 1, 1, 0.16)

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: "▶"
                font.family: Style.font.family
                font.pixelSize: Style.space(9)
                color: "#ffffff"
              }

              MouseArea {
                id: ytmHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (sideWindow.studio) sideWindow.studio.openMusicDrawer()
              }
            }
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: (sideWindow.studio && sideWindow.studio.hasMedia) ? (sideWindow.studio.trackArtist || "YouTube Music") : "Pulsa OPT+Y para elegir música"
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            color: "#9ca3b2"
            elide: Text.ElideRight
          }
        }

        // Seek Progress Bar + Elapsed / Total Time
        Column {
          width: parent.width
          spacing: Style.space(5)

          Item {
            width: parent.width
            height: Style.space(14)

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 3
              radius: 1.5
              color: Qt.rgba(1, 1, 1, 0.18)

              Rectangle {
                width: parent.width * (sideWindow.studio ? sideWindow.studio.progress : 0)
                height: parent.height
                radius: parent.radius
                color: sideWindow.creamColor
              }

              Rectangle {
                x: Math.max(0, Math.min(parent.width - width, parent.width * (sideWindow.studio ? sideWindow.studio.progress : 0) - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(8)
                height: Style.space(8)
                radius: width / 2
                color: "#ffffff"
                border.width: 1.5
                border.color: "#181a20"
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                if (sideWindow.studio && width > 0) {
                  sideWindow.studio.seekToRatio(mouse.x / width)
                }
              }
            }
          }

          Item {
            width: parent.width
            height: Style.space(14)

            Text {
              anchors.left: parent.left
              textFormat: Text.PlainText
              text: sideWindow.studio ? sideWindow.studio.formattedPosition : "0:00"
              font.family: Style.font.family
              font.pixelSize: Style.space(11)
              color: "#8f96a6"
            }

            Text {
              anchors.right: parent.right
              textFormat: Text.PlainText
              text: sideWindow.studio ? sideWindow.studio.formattedLength : "0:00"
              font.family: Style.font.family
              font.pixelSize: Style.space(11)
              color: "#8f96a6"
            }
          }
        }

        // Transport Controls: |<   ( || )   >|
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(28)

          Item {
            width: Style.space(32)
            height: Style.space(44)

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: "󰒮"
              font.family: Style.font.family
              font.pixelSize: Style.space(18)
              color: "#eef0f6"
              opacity: prevMouse.containsMouse ? 1.0 : 0.80
            }

            MouseArea {
              id: prevMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (sideWindow.studio) sideWindow.studio.prevTrack()
            }
          }

          // Center circular Play/Pause button (exact match to 02_work_studio_sidepanel.jpg)
          Rectangle {
            width: Style.space(46)
            height: Style.space(46)
            radius: width / 2
            color: playMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            border.width: 1.4
            border.color: sideWindow.creamColor

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: (sideWindow.studio && sideWindow.studio.isPlaying) ? "󰏤" : "󰐊"
              font.family: Style.font.family
              font.pixelSize: Style.space(20)
              color: "#ffffff"
            }

            MouseArea {
              id: playMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (sideWindow.studio) sideWindow.studio.togglePlay()
            }
          }

          Item {
            width: Style.space(32)
            height: Style.space(44)

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: "󰒭"
              font.family: Style.font.family
              font.pixelSize: Style.space(18)
              color: "#eef0f6"
              opacity: nextMouse.containsMouse ? 1.0 : 0.80
            }

            MouseArea {
              id: nextMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (sideWindow.studio) sideWindow.studio.nextTrack()
            }
          }
        }
      }
    }

    // Outer subtle rounded card frame border (drawn on top of loft + player)
    Rectangle {
      z: 5
      anchors.fill: parent
      radius: studioCard.radius
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(Commons.Color.accent.r * 0.45 + 0.55, Commons.Color.accent.g * 0.45 + 0.55, Commons.Color.accent.b * 0.45 + 0.55, 0.24)
    }
  }
}
