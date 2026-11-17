import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "cosmos.settings"

  readonly property string cosmosCtl: Quickshell.env("HOME") + "/.local/bin/cosmos-ctl"
  implicitWidth: 28
  implicitHeight: 26

  Rectangle {
    id: pillBg
    width: 24
    height: 24
    radius: 12
    anchors.centerIn: parent
    color: hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    border.color: hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(1, 1, 1, 0.14)

    // Cosmos rounded-square emblem (rounded-square Cosmos emblem)
    Rectangle {
      width: 12
      height: 12
      radius: 3.5
      anchors.centerIn: parent
      color: "#f2f5fa"

      Rectangle {
        width: 5.5
        height: 5.5
        radius: 1.6
        anchors.centerIn: parent
        color: "#14181e"
      }
    }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        Quickshell.execDetached([root.cosmosCtl, "studio", "toggle"])
      } else {
        Quickshell.execDetached([root.cosmosCtl, "settings", "toggle"])
      }
    }
  }
}
