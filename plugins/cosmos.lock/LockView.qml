import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property string videoPosterPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintUnavailable: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  // Cosmos extensions
  property string rainMode: "drizzle"
  property double lockedSinceMs: 0
  property bool isPreview: false
  property int needsYouCount: 0
  property int workingCount: 0
  property int finishedCount: 0
  property int totalAgentCount: 0

  property real rainTime: 0.0
  property string clockString: "00:00"
  property string dateString: ""
  property string lockedAgoString: "Locked just now"

  readonly property string placeholderText: Commons.I18n.t("lock.enterPassword")
  readonly property int fieldWidth: 396
  readonly property int fieldHeight: 54
  readonly property int outlineThickness: 1
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.0)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.15)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.22)

  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Commons.Color.lock.borderError, 2, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Qt.rgba(1, 1, 1, 0.28), 1, "border-alpha")

  readonly property bool video: Util.isVideoPath(root.backgroundPath)

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function updateClockStrings() {
    var now = new Date()
    var hh = String(now.getHours())
    if (hh.length < 2) hh = "0" + hh
    var mm = String(now.getMinutes())
    if (mm.length < 2) mm = "0" + mm
    root.clockString = hh + ":" + mm

    try {
      var loc = Qt.locale(Commons.I18n.formatLocale)
      root.dateString = loc.toString(now, "dddd, d MMMM")
    } catch (e) {
      root.dateString = Qt.formatDate(now, "dddd, d MMMM")
    }

    if (root.lockedSinceMs <= 0) {
      root.lockedAgoString = "Locked just now"
    } else {
      var diffMin = Math.floor(Math.max(0, Date.now() - root.lockedSinceMs) / 60000)
      if (diffMin < 1) root.lockedAgoString = "Locked just now"
      else if (diffMin < 60) root.lockedAgoString = "Locked " + diffMin + "m ago"
      else {
        var hrs = Math.floor(diffMin / 60)
        var rem = diffMin % 60
        root.lockedAgoString = rem > 0 ? ("Locked " + hrs + "h " + rem + "m ago") : ("Locked " + hrs + "h ago")
      }
    }
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function dropsAutoRepeat(key) {
    return key !== Qt.Key_Backspace && key !== Qt.Key_Delete
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onLoadBackgroundChanged: if (loadBackground) updateClockStrings()
  onLockedSinceMsChanged: updateClockStrings()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    updateClockStrings()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Only runs while locked or previewing (0% CPU/GPU while unlocked!)
  Timer {
    interval: 55
    repeat: true
    running: root.loadBackground && root.visible && root.rainMode !== "clear"
    onTriggered: root.rainTime += 0.055
  }

  Timer {
    interval: 2000
    repeat: true
    running: root.loadBackground && root.visible
    onTriggered: root.updateClockStrings()
  }

  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Commons.Color.background

    BackgroundMedia {
      id: wallpaper
      objectName: "lockWallpaper"
      anchors.fill: parent
      path: root.loadBackground ? (root.video ? root.videoPosterPath : root.backgroundPath) : ""
      version: root.backgroundVersion
      cached: true
      constrainDecode: true
      decodeSize: Qt.size(width, height)
    }

    // Soft condensation blur pass fed into the optical raindrop shader
    MultiEffect {
      id: mistWall
      anchors.fill: wallpaper
      source: wallpaper
      visible: false
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.ready
      blur: 0.22
      blurMax: 20
      blurMultiplier: 1.0
      contrast: -0.02
    }

    ShaderEffectSource {
      id: sharpTexSource
      sourceItem: wallpaper
      anchors.fill: wallpaper
      live: true
      hideSource: true
      visible: false
    }

    ShaderEffectSource {
      id: mistTexSource
      sourceItem: mistWall
      anchors.fill: wallpaper
      live: true
      hideSource: false
      visible: false
    }

    // Offline GLSL Optical Raindrop Refraction Shader (.qsb)
    ShaderEffect {
      id: rainShader
      anchors.fill: parent
      visible: root.loadBackground && wallpaper.ready
      fragmentShader: Qt.resolvedUrl("shaders/rain.frag.qsb")

      property var sharpTex: sharpTexSource
      property var mistTex: mistTexSource
      property real uTime: root.rainTime
      property real uAspect: (width > 0 && height > 0) ? (width / height) : 1.7778
      property real uIntensity: root.rainMode === "downpour" ? 2.1 : (root.rainMode === "clear" ? 0.0 : 1.0)
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    // Centered Smoked-Glass Password Pill positioned in the lower third (smoked-glass password input)
    BorderSurface {
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(128)
      color: Qt.rgba(0.08, 0.10, 0.12, 0.78)
      borderSpec: root.inputBorderSpec
      radius: Style.space(10)
      clip: true

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: "#f4f6fa"
        selectionColor: Commons.Color.lock.selection
        selectedTextColor: "#ffffff"
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: "#f4f6fa"
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.isAutoRepeat && root.dropsAutoRepeat(event.key)) {
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: passwordInput
        text: root.isPreview ? "••••••" : (root.authenticatingPassword ? Commons.I18n.t("lock.checking") : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText))
        visible: passwordInput.text.length === 0
        color: root.isPreview ? "#e8ecf4" : (root.authenticatingPassword ? "#f4f6fa" : (root.failureMessage.length > 0 ? Commons.Color.lock.textError : Qt.rgba(0.92, 0.94, 0.98, 0.58)))
        font.family: Style.font.family
        font.pixelSize: root.isPreview ? root.passwordDotFontSize : root.fieldFontSize
        font.letterSpacing: root.isPreview ? 5 : 0
        font.italic: !root.isPreview && !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        textFormat: Text.PlainText
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: root.fingerprintUnavailable ? "󰺱" : "󰈷"
        color: root.fingerprintUnavailable ? Commons.Color.lock.textError : Qt.rgba(1, 1, 1, 0.55)
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    Text {
      objectName: "fingerprintUnavailableNotice"
      textFormat: Text.PlainText
      anchors.top: inputField.bottom
      anchors.topMargin: 18
      anchors.horizontalCenter: inputField.horizontalCenter
      visible: root.fingerprintConfigured && root.fingerprintUnavailable
      text: Commons.I18n.t("lock.fingerprintUnavailable")
      color: Commons.Color.lock.textError
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.italic: true
      horizontalAlignment: Text.AlignHCenter
    }

    // -----------------------------------------------------------------
    // Bottom-Left Cosmos Signature Lock HUD (Gradient Clock + Agent Info)
    // -----------------------------------------------------------------
    Column {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.leftMargin: Style.space(44)
      anchors.bottomMargin: Style.space(38)
      spacing: Style.space(6)

      // 1. Large Horizontal-Gradient Clock ("17:55")
      Item {
        width: clockGlyphs.implicitWidth + Style.space(6)
        height: clockGlyphs.implicitHeight

        Text {
          id: clockGlyphs
          visible: false
          textFormat: Text.PlainText
          text: root.clockString
          font.family: Style.font.family
          font.pixelSize: Style.space(94)
          font.weight: Font.Normal
          color: "#ffffff"
        }

        ShaderEffectSource {
          id: clockGlyphSource
          sourceItem: clockGlyphs
          anchors.fill: parent
          live: true
          hideSource: true
          visible: false
        }

        ShaderEffect {
          anchors.fill: parent
          fragmentShader: Qt.resolvedUrl("shaders/clock_gradient.frag.qsb")
          property var glyphTex: clockGlyphSource
          property vector4d uColorA: Qt.vector4d(0.97, 0.85, 0.50, 1.0)
          property vector4d uColorB: Qt.vector4d(0.75, 0.90, 0.88, 1.0)
          property vector4d uColorC: Qt.vector4d(0.86, 0.74, 0.96, 1.0)
        }
      }

      // 2. Date Line ("Tuesday, 17 November")
      Text {
        textFormat: Text.PlainText
        text: root.dateString
        font.family: Style.font.family
        font.pixelSize: Style.space(18)
        font.weight: Font.Medium
        color: "#f2f5fa"
      }

      Item { width: 1; height: Style.space(6) }

      // 3. Private Live Agent Summary (counts only — zero prompts/titles exposed!)
      Row {
        visible: root.totalAgentCount > 0
        spacing: Style.space(7)

        Rectangle {
          width: Style.space(7)
          height: Style.space(7)
          radius: width / 2
          anchors.verticalCenter: parent.verticalCenter
          color: root.needsYouCount > 0 ? "#f5b041" : (root.workingCount > 0 ? "#38bdf8" : "#4ade80")
        }

        Text {
          textFormat: Text.PlainText
          text: {
            var parts = []
            if (root.needsYouCount > 0) {
              parts.push(root.needsYouCount + (root.needsYouCount === 1 ? " agent needs you" : " agents need you"))
            }
            if (root.workingCount > 0) {
              parts.push(root.workingCount + " working")
            }
            if (root.finishedCount > 0) {
              parts.push(root.finishedCount + " finished")
            }
            return parts.join("  ·  ")
          }
          font.family: Style.font.family
          font.pixelSize: Style.space(14)
          font.weight: Font.Medium
          color: root.needsYouCount > 0 ? "#f5b041" : "#e6ebf4"
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // 4. Relative Lock Duration ("Locked just now")
      Text {
        textFormat: Text.PlainText
        text: root.lockedAgoString
        font.family: Style.font.family
        font.pixelSize: Style.space(13)
        color: Qt.rgba(0.88, 0.91, 0.96, 0.68)
      }
    }
  }
}
