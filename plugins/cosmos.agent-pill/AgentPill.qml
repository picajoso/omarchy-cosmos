import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  property var bar: null
  property var shell: null
  property var settings: ({})
  property string moduleName: "cosmos.agent-pill"

  readonly property bool vertical: !!bar && bar.vertical
  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")

  property int needsYouCount: 0
  property int workingCount: 0
  property int finishedCount: 0
  property int totalCount: 0
  property string headlineStatus: "idle"
  property string urgentSummary: "Cosmos Studio (OPT+D)"

  readonly property color amberColor: "#f4a940"
  readonly property color greenColor: "#4ade80"
  readonly property color eyeColor: {
    if (needsYouCount > 0) return amberColor
    if (workingCount > 0) return Commons.Color.accent
    if (finishedCount > 0) return greenColor
    return root.bar ? root.bar.barForeground : Commons.Color.foreground
  }

  implicitWidth: vertical ? (bar ? bar.barSize : Style.space(34)) : pillBtn.implicitWidth
  implicitHeight: vertical ? Style.space(28) : (bar ? bar.barSize : Style.space(34))

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
      if (data.mostUrgent && data.mostUrgent.agentName) {
        urgentSummary = String(data.mostUrgent.agentName) + ": " + String(data.mostUrgent.title || "") + " (clic: Studio · clic der: ir)"
      } else {
        urgentSummary = "Cosmos Studio (clic o OPT+D)"
      }
    } catch (e) {
    }
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

  ShellIpc {
    target: "cosmos.agent-pill"

    function syncAgents(): void {
      agentsFile.reload()
    }
  }

  WidgetButton {
    id: pillBtn
    anchors.verticalCenter: parent.verticalCenter
    fixedHeight: root.vertical ? Style.space(26) : (root.bar ? root.bar.barSize : Style.space(34))
    fixedWidth: root.vertical ? Style.space(26) : (pillRow.implicitWidth + Style.space(10))
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    tooltipText: root.urgentSummary

    onPressed: function(button) {
      if (button === Qt.RightButton) {
        Quickshell.execDetached([root.home + "/.local/bin/cosmos-ctl", "focus-agent"])
      } else {
        Quickshell.execDetached([root.home + "/.local/bin/cosmos-ctl", "studio", "toggle"])
      }
    }

    Row {
      id: pillRow
      anchors.centerIn: parent
      spacing: Style.space(6)

      // Cute Cosmos mini-robot head visor icon
      Item {
        width: Style.space(20)
        height: Style.space(18)
        anchors.verticalCenter: parent.verticalCenter

        // Little antenna
        Rectangle {
          x: Style.space(4)
          y: 0
          width: 1.5
          height: Style.space(4)
          rotation: -18
          color: root.amberColor
          opacity: 0.85
        }

        // Outer white/silver helmet
        Rectangle {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          width: Style.space(18)
          height: Style.space(14)
          radius: Style.space(6)
          color: "#e9ecf2"
          border.width: 1
          border.color: "#8b92a2"

          // Side ear-pods
          Rectangle {
            x: -2
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: Style.space(7)
            radius: 1.5
            color: "#c8a96b"
          }
          Rectangle {
            x: parent.width - 1
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: Style.space(7)
            radius: 1.5
            color: "#c8a96b"
          }

          // Dark glossy visor
          Rectangle {
            anchors.centerIn: parent
            width: Style.space(13)
            height: Style.space(8)
            radius: Style.space(4)
            color: "#12141a"

            Row {
              anchors.centerIn: parent
              spacing: Style.space(3)

              Rectangle {
                width: 2.2
                height: Style.space(4)
                radius: 1.1
                color: root.eyeColor
              }
              Rectangle {
                width: 2.2
                height: Style.space(4)
                radius: 1.1
                color: root.eyeColor
              }
            }
          }
        }
      }

      // Needs-you amber pill badge ("? 1 needs you")
      Row {
        visible: !root.vertical && root.needsYouCount > 0
        spacing: Style.space(4)
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          width: Style.space(13)
          height: Style.space(13)
          radius: 4
          color: root.amberColor
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "?"
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.space(9)
            font.bold: true
            color: "#161412"
          }
        }

        Text {
          textFormat: Text.PlainText
          text: root.needsYouCount + (root.needsYouCount === 1 ? " needs you" : " need you")
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          color: root.amberColor
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // Working badge ("1 working") when no urgent question
      Row {
        visible: !root.vertical && root.needsYouCount === 0 && root.workingCount > 0
        spacing: Style.space(4)
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          width: Style.space(7)
          height: Style.space(7)
          radius: width / 2
          color: Commons.Color.accent
          anchors.verticalCenter: parent.verticalCenter

          SequentialAnimation on opacity {
            running: root.workingCount > 0
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.35; duration: 750; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.35; to: 1.0; duration: 750; easing.type: Easing.InOutSine }
          }
        }

        Text {
          textFormat: Text.PlainText
          text: root.workingCount + " working"
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          color: root.bar ? root.bar.barForeground : Commons.Color.foreground
          opacity: 0.90
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // Finished emerald badge ("✓ 2")
      Row {
        visible: !root.vertical && root.finishedCount > 0
        spacing: Style.space(3)
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          width: Style.space(13)
          height: Style.space(13)
          radius: width / 2
          color: root.greenColor
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "✓"
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.space(9)
            font.bold: true
            color: "#0f1912"
          }
        }

        Text {
          textFormat: Text.PlainText
          text: String(root.finishedCount)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          color: root.greenColor
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
