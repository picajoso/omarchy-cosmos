import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Commons as Commons

PanelWindow {
  id: pinWindow

  property var studio: null

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

  readonly property bool pinsVisible: !!studio && windowCount === 0
  readonly property string pinLayout: studio ? studio.pinLayout : "left"
  readonly property color amberColor: "#f4a940"
  readonly property color greenColor: "#4ade80"

  color: "transparent"
  surfaceFormat.opaque: false
  WlrLayershell.namespace: "cosmos-pins"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  mask: pinsVisible ? activeMask : emptyMask

  Region {
    id: activeMask
    item: pinsContainer
  }

  Region {
    id: emptyMask
    item: zeroHitbox
  }

  Item {
    id: zeroHitbox
    width: 0
    height: 0
  }

  Item {
    id: pinsContainer
    width: pinFlow.implicitWidth + Style.space(28)
    height: pinFlow.implicitHeight + Style.space(24)

    x: {
      if (pinWindow.pinLayout === "center") return Math.round((parent.width - width) / 2)
      if (pinWindow.pinLayout === "right") return Math.round(parent.width - width - Style.space(42))
      return Style.space(42)
    }
    y: Math.round(parent.height - height - Style.space(38) + (pinWindow.pinsVisible ? 0 : Style.space(14)))

    opacity: pinWindow.pinsVisible ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // Subtle frosted ambient backdrop so pins read crisply over both bright snow and pitch-black skies
    Rectangle {
      anchors.fill: parent
      radius: Style.space(22)
      color: Qt.rgba(Commons.Color.background.r, Commons.Color.background.g, Commons.Color.background.b, 0.34)
      border.width: 1
      border.color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.10)
    }

    Grid {
      id: pinFlow
      anchors.centerIn: parent
      columns: pinWindow.pinLayout === "center" ? 2 : 1
      columnSpacing: Style.space(36)
      rowSpacing: Style.space(18)

      // 1. Agents Pin
      Item {
        width: Style.space(340)
        height: Style.space(90)

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(16)

          // Circular Robot Loft Medallion
          Item {
            width: Style.space(84)
            height: Style.space(84)
            anchors.verticalCenter: parent.verticalCenter

            ClippingRectangle {
              anchors.fill: parent
              radius: width / 2
              color: "#121726"

              StudioScene {
                anchors.fill: parent
                compact: true
                active: pinWindow.pinsVisible
                totalCount: pinWindow.studio ? pinWindow.studio.totalCount : 0
                needsYouCount: pinWindow.studio ? pinWindow.studio.needsYouCount : 0
                workingCount: pinWindow.studio ? pinWindow.studio.workingCount : 0
                finishedCount: pinWindow.studio ? pinWindow.studio.finishedCount : 0
                crewList: pinWindow.studio ? pinWindow.studio.crewList : []
                accentColor: Commons.Color.accent
              }
            }

            // Status ring around medallion
            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: "transparent"
              border.width: 2
              border.color: {
                if (!pinWindow.studio) return Qt.rgba(1, 1, 1, 0.25)
                if (pinWindow.studio.needsYouCount > 0) return pinWindow.amberColor
                if (pinWindow.studio.workingCount > 0) return Commons.Color.accent
                if (pinWindow.studio.finishedCount > 0) return pinWindow.greenColor
                return Qt.rgba(1, 1, 1, 0.25)
              }
            }

            // Floating mini status badge top-right of medallion
            Rectangle {
              visible: !!pinWindow.studio && pinWindow.studio.totalCount > 0
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(2)
              width: Style.space(22)
              height: Style.space(22)
              radius: width / 2
              color: {
                if (!pinWindow.studio) return "#222"
                if (pinWindow.studio.needsYouCount > 0) return pinWindow.amberColor
                if (pinWindow.studio.workingCount > 0) return Commons.Color.accent
                return pinWindow.greenColor
              }
              border.width: 2
              border.color: "#141416"

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: {
                  if (!pinWindow.studio) return ""
                  if (pinWindow.studio.needsYouCount > 0) return "?"
                  if (pinWindow.studio.workingCount > 0) return "⚡"
                  return "✓"
                }
                font.family: Style.font.family
                font.pixelSize: Style.space(11)
                font.bold: true
                color: "#121316"
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: if (pinWindow.studio) pinWindow.studio.focusMostUrgentAgent()
            }
          }

          Column {
            width: Style.space(236)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Text {
              textFormat: Text.PlainText
              text: pinWindow.studio ? pinWindow.studio.headlineLabel : "Ready"
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              color: {
                if (pinWindow.studio && pinWindow.studio.needsYouCount > 0) return pinWindow.amberColor
                if (pinWindow.studio && pinWindow.studio.workingCount > 0) return Commons.Color.accent
                return Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.72)
              }
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: pinWindow.studio ? pinWindow.studio.urgentTitle : "Cosmos Studio"
              font.family: Style.font.family
              font.pixelSize: Style.space(19)
              font.bold: true
              color: Commons.Color.foreground
              elide: Text.ElideRight
            }

            Item {
              width: agentLinkLabel.implicitWidth
              height: agentLinkLabel.implicitHeight + Style.space(2)

              Text {
                id: agentLinkLabel
                textFormat: Text.PlainText
                text: {
                  var n = pinWindow.studio ? pinWindow.studio.totalCount : 0
                  if (n <= 0) return "Abrir Cosmos Studio ↗"
                  return n + (n === 1 ? " agent ↗" : " agents ↗")
                }
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.78)
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (pinWindow.studio) pinWindow.studio.focusMostUrgentAgent()
              }
            }
          }
        }
      }

      // 2. Now Playing Pin (with subtle top hairline when stacked vertically)
      Column {
        spacing: Style.space(14)

        Rectangle {
          visible: pinWindow.pinLayout !== "center"
          width: Style.space(332)
          height: 1
          color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.14)
        }

        Item {
          width: Style.space(340)
          height: Style.space(92)

          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(16)

            VinylDiscView {
              discSize: Style.space(84)
              artUrl: pinWindow.studio ? pinWindow.studio.artUrl : ""
              playing: pinWindow.studio ? pinWindow.studio.isPlaying : false
              progress: pinWindow.studio ? pinWindow.studio.progress : 0.0
              accentColor: Commons.Color.accent
              anchors.verticalCenter: parent.verticalCenter
              onClicked: if (pinWindow.studio) pinWindow.studio.togglePlay()
            }

            Column {
              width: Style.space(236)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(3)

              Text {
                textFormat: Text.PlainText
                text: (pinWindow.studio && pinWindow.studio.hasMedia) ? "NOW PLAYING" : "YOUTUBE MUSIC"
                font.family: Style.font.family
                font.pixelSize: Style.space(10)
                font.bold: true
                font.letterSpacing: 1.1
                color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.62)
              }

              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: (pinWindow.studio && pinWindow.studio.hasMedia) ? pinWindow.studio.trackTitle : "Reproducir música"
                font.family: Style.font.family
                font.pixelSize: Style.space(18)
                font.bold: true
                color: Commons.Color.foreground
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: (pinWindow.studio && pinWindow.studio.hasMedia) ? (pinWindow.studio.trackArtist || "YouTube Music") : "Pulsa OPT+Y o haz clic en el vinilo"
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.72)
                elide: Text.ElideRight
              }

              // Inline mini controls + progress bar (like 01_desktop_leviathan.jpg)
              Row {
                width: parent.width
                spacing: Style.space(10)

                Text {
                  textFormat: Text.PlainText
                  text: "󰒮"
                  font.family: Style.font.family
                  font.pixelSize: Style.space(13)
                  color: Commons.Color.foreground
                  opacity: (pinWindow.studio && pinWindow.studio.hasMedia) ? 0.85 : 0.35

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (pinWindow.studio) pinWindow.studio.prevTrack()
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  text: (pinWindow.studio && pinWindow.studio.isPlaying) ? "󰏤" : "󰐊"
                  font.family: Style.font.family
                  font.pixelSize: Style.space(14)
                  color: Commons.Color.foreground

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (pinWindow.studio) pinWindow.studio.togglePlay()
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  text: "󰒭"
                  font.family: Style.font.family
                  font.pixelSize: Style.space(13)
                  color: Commons.Color.foreground
                  opacity: (pinWindow.studio && pinWindow.studio.hasMedia) ? 0.85 : 0.35

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (pinWindow.studio) pinWindow.studio.nextTrack()
                  }
                }

                Item {
                  width: Style.space(146)
                  height: Style.space(14)
                  anchors.verticalCenter: parent.verticalCenter

                  Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 2.5
                    radius: 1.5
                    color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.22)

                    Rectangle {
                      width: parent.width * (pinWindow.studio ? pinWindow.studio.progress : 0)
                      height: parent.height
                      radius: parent.radius
                      color: Commons.Color.accent
                    }

                    Rectangle {
                      visible: !!pinWindow.studio && pinWindow.studio.hasMedia
                      x: Math.max(0, Math.min(parent.width - width, parent.width * (pinWindow.studio ? pinWindow.studio.progress : 0) - width / 2))
                      anchors.verticalCenter: parent.verticalCenter
                      width: Style.space(7)
                      height: Style.space(7)
                      radius: width / 2
                      color: Commons.Color.accent
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                      if (pinWindow.studio && width > 0) {
                        pinWindow.studio.seekToRatio(mouse.x / width)
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
