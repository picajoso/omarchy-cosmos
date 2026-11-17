import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Commons as Commons

Item {
  id: root

  property real discSize: 196
  property string artUrl: ""
  property bool playing: false
  property real progress: 0.0
  property color accentColor: Commons.Color.accent
  property bool showProgressRing: true
  property bool showTonearm: true

  signal clicked()

  width: discSize
  height: discSize

  // Outer subtle shadow/halo ring
  Rectangle {
    anchors.centerIn: parent
    width: root.discSize
    height: root.discSize
    radius: width / 2
    color: "#101217"
    border.width: 1.5
    border.color: Qt.rgba(1, 1, 1, 0.16)
  }

  // Circular progress arc around outer rim
  Canvas {
    id: progressArc
    visible: root.showProgressRing
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var cx = width / 2
      var cy = height / 2
      var r = (Math.min(width, height) / 2) - 2.5
      if (r <= 4) return

      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.strokeStyle = "rgba(255, 255, 255, 0.10)"
      ctx.lineWidth = 2.2
      ctx.stroke()

      var p = Math.max(0.0, Math.min(1.0, root.progress))
      if (p > 0.002) {
        var start = -Math.PI / 2
        var end = start + p * Math.PI * 2
        ctx.beginPath()
        ctx.arc(cx, cy, r, start, end)
        ctx.strokeStyle = String(root.accentColor)
        ctx.lineWidth = 2.4
        ctx.lineCap = "round"
        ctx.stroke()
      }
    }
  }

  onProgressChanged: progressArc.requestPaint()
  onAccentColorChanged: progressArc.requestPaint()
  onWidthChanged: progressArc.requestPaint()

  // Rotating vinyl record + album cover
  Item {
    id: platter
    anchors.centerIn: parent
    width: root.discSize - (root.showProgressRing ? 12 : 4)
    height: width

    RotationAnimator on rotation {
      from: 0
      to: 360
      duration: 11000
      loops: Animation.Infinite
      running: root.visible && root.playing
    }

    ClippingRectangle {
      anchors.fill: parent
      radius: width / 2
      color: "#15171d"

      // Full-bleed album art with vinyl aesthetic
      Image {
        anchors.fill: parent
        source: root.artUrl
        sourceSize.width: 384
        sourceSize.height: 384
        fillMode: Image.PreserveAspectCrop
        visible: root.artUrl !== ""
        opacity: 0.90
      }

      // Fallback stylized label if no art yet
      Rectangle {
        anchors.centerIn: parent
        visible: root.artUrl === ""
        width: parent.width * 0.44
        height: width
        radius: width / 2
        color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.28)
        border.width: 1
        border.color: root.accentColor
      }

      // Concentric vinyl grooves overlay
      Repeater {
        model: [0.88, 0.76, 0.64, 0.52, 0.38]
        delegate: Rectangle {
          required property real modelData
          anchors.centerIn: parent
          width: parent.width * modelData
          height: width
          radius: width / 2
          color: "transparent"
          border.width: 1
          border.color: Qt.rgba(0, 0, 0, 0.26)
        }
      }

      // Specular vinyl diagonal highlight
      Rectangle {
        anchors.fill: parent
        radius: width / 2
        rotation: -32
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
          GradientStop { position: 0.42; color: "transparent" }
          GradientStop { position: 0.58; color: "transparent" }
          GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.10) }
        }
      }

      // Center vinyl hub & spindle hole
      Rectangle {
        anchors.centerIn: parent
        width: Math.max(12, parent.width * 0.13)
        height: width
        radius: width / 2
        color: "#181a20"
        border.width: 1.5
        border.color: Qt.rgba(1, 1, 1, 0.24)

        Rectangle {
          anchors.centerIn: parent
          width: Math.max(4, parent.width * 0.36)
          height: width
          radius: width / 2
          color: "#090a0d"
        }
      }
    }
  }

  // Stylized turntable tonearm on the right side (pivots onto record when playing!)
  Item {
    id: tonearmAssembly
    visible: root.showTonearm
    width: parent.width
    height: parent.height
    transformOrigin: Item.TopRight

    // Pivot base top-right
    Rectangle {
      id: armPivot
      x: parent.width * 0.84 - width / 2
      y: parent.height * 0.17 - height / 2
      width: Math.max(8, root.discSize * 0.075)
      height: width
      radius: width / 2
      color: "#2b2e36"
      border.width: 1.5
      border.color: "#d4c39a"
    }

    Item {
      x: armPivot.x + armPivot.width / 2
      y: armPivot.y + armPivot.height / 2
      width: 1
      height: 1
      rotation: root.playing ? 17 : 5

      Behavior on rotation {
        NumberAnimation { duration: 420; easing.type: Easing.OutBack }
      }

      // Main metallic arm shaft
      Rectangle {
        x: -1.5
        y: 0
        width: Math.max(2.5, root.discSize * 0.018)
        height: root.discSize * 0.54
        radius: width / 2
        color: "#dfd2b2"
      }

      // Angled headshell & cartridge
      Rectangle {
        x: -Math.max(4, root.discSize * 0.032)
        y: root.discSize * 0.51
        width: Math.max(6, root.discSize * 0.048)
        height: Math.max(10, root.discSize * 0.085)
        radius: 2
        rotation: 24
        color: "#1e2026"
        border.width: 1.2
        border.color: "#dfd2b2"
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
