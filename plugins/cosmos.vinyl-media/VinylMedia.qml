import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "cosmos.vinyl-media"

  readonly property string home: Quickshell.env("HOME")
  readonly property string cosmosCtl: home + "/.local/bin/cosmos-ctl"

  readonly property var players: Mpris.players ? Mpris.players.values : []

  function scorePlayer(p) {
    if (!p) return -1
    var score = 0
    if (p.isPlaying) score += 100
    var ident = String(p.identity || p.desktopEntry || "").toLowerCase()
    var title = String(p.trackTitle || "").toLowerCase()
    if (ident.indexOf("youtube") !== -1 || ident.indexOf("chromium") !== -1 || ident.indexOf("brave") !== -1 || ident.indexOf("chrome") !== -1 || ident.indexOf("firefox") !== -1) {
      score += 25
    }
    if (p.trackTitle || p.trackArtist) score += 50
    if (p.trackArtUrl) score += 10
    if (title.length > 0) score += 5
    return score
  }

  readonly property var activePlayer: {
    var best = null
    var bestScore = -1
    for (var i = 0; i < players.length; i++) {
      var p = players[i]
      if (!p) continue
      var s = scorePlayer(p)
      if (s > bestScore) {
        bestScore = s
        best = p
      }
    }
    return bestScore >= 5 ? best : null
  }

  function cleanStr(val, maxLen) {
    var s = String(val || "").replace(/[\r\n\t]+/g, " ").trim()
    if (s.length > maxLen) return s.slice(0, maxLen - 1) + "…"
    return s
  }

  readonly property bool hasMedia: activePlayer !== null && (String(activePlayer.trackTitle || "") !== "" || String(activePlayer.trackArtist || "") !== "")
  readonly property bool isPlaying: !!activePlayer && !!activePlayer.isPlaying
  readonly property string title: hasMedia ? cleanStr(activePlayer.trackTitle, 90) : ""
  readonly property string artist: hasMedia ? cleanStr(activePlayer.trackArtist, 60) : ""
  readonly property string artUrl: activePlayer && activePlayer.trackArtUrl ? String(activePlayer.trackArtUrl) : ""
  readonly property string displayLine: {
    if (!hasMedia) return ""
    if (artist && title) return artist + " — " + title
    return title || artist
  }

  readonly property real discSize: root.vertical ? Math.max(Style.space(24), root.barSize - Style.space(2)) : Style.space(42)
  property bool popupOpen: false
  function close() { popupOpen = false }

  function openMusicApp() {
    Quickshell.execDetached([root.cosmosCtl, "music-open"])
  }

  function togglePlay() {
    if (root.activePlayer) {
      root.activePlayer.togglePlaying()
    } else {
      openMusicApp()
    }
  }

  function prevTrack() {
    if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
  }

  function nextTrack() {
    if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
  }

  visible: true
  implicitWidth: root.vertical ? root.barSize : contentRow.implicitWidth + Style.space(8)
  implicitHeight: root.vertical ? contentRow.implicitHeight + Style.space(8) : root.barSize

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.space(4)

    // Previous button
    WidgetButton {
      visible: !root.vertical && root.hasMedia
      bar: root.bar
      text: "󰒮"
      fontSize: Style.space(13)
      fixedWidth: Style.space(22)
      fixedHeight: root.barSize
      tooltipText: "Anterior"
      onPressed: function() { root.prevTrack() }
    }

    // Play / Pause circular subtle pill button
    WidgetButton {
      id: playBtn
      visible: !root.vertical && root.hasMedia
      bar: root.bar
      labelVisible: false
      hasVisualContent: true
      fixedWidth: Style.space(24)
      fixedHeight: root.barSize
      tooltipText: root.isPlaying ? "Pausar" : "Reproducir"
      onPressed: function() { root.togglePlay() }

      Rectangle {
        anchors.centerIn: parent
        width: Style.space(22)
        height: Style.space(22)
        radius: width / 2
        scale: playBtn.pressScale
        color: Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.22)
        border.width: 1
        border.color: Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.38)

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.isPlaying ? "󰏤" : "󰐊"
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.space(12)
          color: root.bar ? root.bar.barForeground : Commons.Color.foreground
        }
      }
    }

    // Next button
    WidgetButton {
      visible: !root.vertical && root.hasMedia
      bar: root.bar
      text: "󰒭"
      fontSize: Style.space(13)
      fixedWidth: Style.space(22)
      fixedHeight: root.barSize
      tooltipText: "Siguiente"
      onPressed: function() { root.nextTrack() }
    }

    // Center protruding Vinyl / Album Art Disc (extends above and below bar height!)
    WidgetButton {
      id: discButton
      bar: root.bar
      labelVisible: false
      hasVisualContent: true
      fixedWidth: root.discSize + Style.space(4)
      fixedHeight: root.barSize
      tooltipText: root.hasMedia
        ? (root.displayLine + " (clic der. controles · clic central abrir YouTube Music)")
        : "Abrir YouTube Music"

      onPressed: function(button) {
        if (button === Qt.RightButton) {
          root.popupOpen = !root.popupOpen
        } else if (button === Qt.MiddleButton) {
          root.openMusicApp()
        } else {
          root.togglePlay()
        }
      }
      onWheelMoved: function(delta) {
        if (!root.activePlayer) return
        if (delta > 0) root.prevTrack()
        else if (delta < 0) root.nextTrack()
      }

      // Outer rim ring that protrudes cleanly above and below the 34px bar
      Rectangle {
        id: discRim
        anchors.centerIn: parent
        width: root.discSize
        height: root.discSize
        radius: width / 2
        scale: discButton.pressScale
        color: Qt.darker(Commons.Color.background, 1.3)
        border.width: 1.5
        border.color: root.isPlaying
          ? Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.85)
          : Qt.rgba(
              (root.bar ? root.bar.barForeground.r : 0.8),
              (root.bar ? root.bar.barForeground.g : 0.8),
              (root.bar ? root.bar.barForeground.b : 0.8),
              0.48
            )

        ClippingRectangle {
          id: discClip
          anchors.fill: parent
          anchors.margins: 2
          radius: width / 2
          color: "#15171c"

          Item {
            id: spinningPlatter
            anchors.fill: parent

            NumberAnimation on rotation {
              running: root.isPlaying && !Style.reduceMotion
              loops: Animation.Infinite
              from: spinningPlatter.rotation
              to: spinningPlatter.rotation + 360
              duration: 14000
              easing.type: Easing.Linear
            }

            // Default vinyl grooves when no album cover URL is available
            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: "#181a20"
              visible: albumArt.status !== Image.Ready || root.artUrl === ""

              Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.76
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.09)
              }

              Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.54
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)
              }

              Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.36
                height: width
                radius: width / 2
                color: Commons.Color.accent
                opacity: 0.85
              }
            }

            Image {
              id: albumArt
              anchors.fill: parent
              source: root.artUrl
              sourceSize.width: 128
              sourceSize.height: 128
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              smooth: true
              visible: root.artUrl !== "" && status === Image.Ready
            }

            // Subtle vinyl center spindle hole
            Rectangle {
              anchors.centerIn: parent
              width: Style.space(6)
              height: Style.space(6)
              radius: width / 2
              color: "#121318"
              border.width: 1
              border.color: Qt.rgba(1, 1, 1, 0.45)
            }
          }
        }
      }
    }

    // Track label (Artist — Title) + headphone/music icon
    WidgetButton {
      id: trackLabelBtn
      visible: !root.vertical && root.hasMedia
      bar: root.bar
      labelVisible: false
      hasVisualContent: true
      fixedWidth: Math.min(Style.space(155), trackRow.implicitWidth + Style.space(10))
      fixedHeight: root.barSize
      tooltipText: root.displayLine + " (clic para ir a YouTube Music)"
      onPressed: function(button) {
        if (button === Qt.RightButton) root.popupOpen = !root.popupOpen
        else root.openMusicApp()
      }

      Row {
        id: trackRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Style.space(4)
        spacing: Style.space(6)

        Text {
          id: trackText
          textFormat: Text.PlainText
          text: root.displayLine
          width: Math.min(Style.space(126), implicitWidth)
          elide: Text.ElideRight
          color: root.bar ? root.bar.barForeground : Commons.Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          textFormat: Text.PlainText
          text: "󰋋"
          color: root.bar ? root.bar.barForeground : Commons.Color.foreground
          opacity: 0.72
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.space(12)
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  // Right-click mini vinyl popup card
  PopupCard {
    id: popup
    anchorItem: discButton
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(popupCol.implicitHeight)

    Column {
      id: popupCol
      width: parent.width
      spacing: Style.space(12)

      Row {
        width: parent.width
        spacing: Style.space(12)

        ClippingRectangle {
          width: Style.space(72)
          height: Style.space(72)
          radius: width / 2
          color: "#181a20"

          Image {
            anchors.fill: parent
            source: root.artUrl
            sourceSize.width: 192
            sourceSize.height: 192
            fillMode: Image.PreserveAspectCrop
            visible: root.artUrl !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: root.artUrl === ""
            textFormat: Text.PlainText
            text: "󰀥"
            font.family: Style.font.family
            font.pixelSize: Style.space(28)
            color: Commons.Color.accent
          }
        }

        Column {
          width: parent.width - Style.space(84)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(4)

          Text {
            textFormat: Text.PlainText
            text: root.hasMedia ? (root.title || "Reproduciendo") : "YouTube Music"
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
            color: Commons.Color.foreground
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            textFormat: Text.PlainText
            text: root.hasMedia ? (root.artist || "MPRIS activo") : "Sin pista activa"
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            color: Qt.darker(Commons.Color.foreground, 1.3)
            elide: Text.ElideRight
            width: parent.width
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(14)

        Button {
          text: "󰒮"
          enabled: root.hasMedia
          onClicked: root.prevTrack()
        }
        Button {
          text: root.isPlaying ? "󰏤 Pausar" : (root.hasMedia ? "󰐊 Reproducir" : "󰐊 Abrir YT Music")
          onClicked: root.togglePlay()
        }
        Button {
          text: "󰒭"
          enabled: root.hasMedia
          onClicked: root.nextTrack()
        }
      }

      Button {
        width: parent.width
        text: "Mostrar / ocultar ventana YT Music"
        onClicked: {
          root.popupOpen = false
          root.openMusicApp()
        }
      }
    }
  }
}
