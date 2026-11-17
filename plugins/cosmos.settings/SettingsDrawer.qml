import QtQuick
import qs.Commons
import qs.Commons as Commons

FocusScope {
  id: root

  property var cosmosConfig: ({})
  property var appearancesList: []
  property bool introsEnabled: true
  property string currentThemeName: "last-horizon"

  property string activeTab: "appearances"
  property bool saveExpanded: false

  signal runCtlRequested(var args)
  signal closeRequested()
  signal openThemeStudioRequested()

  readonly property string activeAppId: String(cosmosConfig.activeAppearance || "")
  readonly property bool undoPending: cosmosConfig.undoPending === true

  readonly property string activeAppLabel: {
    for (var i = 0; i < appearancesList.length; i++) {
      if (appearancesList[i] && appearancesList[i].id === activeAppId) {
        return String(appearancesList[i].name || "Custom appearance")
      }
    }
    return "Custom appearance (" + currentThemeName + ")"
  }

  Keys.onEscapePressed: root.closeRequested()

  Rectangle {
    anchors.fill: parent
    radius: 16
    color: Qt.rgba(0.075, 0.09, 0.11, 0.88)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.14)
    clip: true

    // Consume clicks inside the drawer so backdrop MouseArea doesn't close it
    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    // -----------------------------------------------------------------
    // 1. Header
    // -----------------------------------------------------------------
    Column {
      id: headerCol
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 18
      spacing: 12

      Row {
        width: parent.width
        spacing: 10

        // Cosmos Emblem
        Rectangle {
          width: 28
          height: 28
          radius: 7
          anchors.verticalCenter: parent.verticalCenter
          color: "#f2f5fa"

          Rectangle {
            width: 12
            height: 12
            radius: 3
            anchors.centerIn: parent
            color: "#12161c"
          }
        }

        Column {
          width: parent.width - 156
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1

          Row {
            spacing: 7
            Text {
              textFormat: Text.PlainText
              text: "Cosmos"
              font.family: Style.font.family
              font.pixelSize: 17
              font.weight: Font.DemiBold
              color: "#f4f6fa"
            }
            Text {
              textFormat: Text.PlainText
              text: "v1.0"
              font.family: Style.font.family
              font.pixelSize: 11
              color: Qt.rgba(0.85, 0.88, 0.94, 0.48)
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 2
            }
          }

          Text {
            textFormat: Text.PlainText
            text: root.activeAppLabel
            font.family: Style.font.family
            font.pixelSize: 11
            color: Qt.rgba(0.86, 0.89, 0.95, 0.65)
            elide: Text.ElideRight
            width: parent.width
          }
        }

        // Badge button -> Theme Studio (260+ themes)
        Rectangle {
          id: studioBadge
          width: 114
          height: 28
          radius: 14
          anchors.verticalCenter: parent.verticalCenter
          color: studioBadgeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.07)
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.16)

          Text {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            text: "260+ themes ↗"
            font.family: Style.font.family
            font.pixelSize: 11
            font.weight: Font.Medium
            color: "#e8ecf4"
          }

          MouseArea {
            id: studioBadgeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openThemeStudioRequested()
          }
        }
      }

      // Quick links row ("Play arrival · Lock preview · Studio panel")
      Row {
        spacing: 14

        Repeater {
          model: [
            { label: "▶ Play arrival", action: ["arrival", "play"], accent: true },
            { label: "Lock preview (OPT+R)", action: ["lock-preview"], accent: false },
            { label: "Toggle Studio", action: ["studio", "toggle"], accent: false }
          ]

          Item {
            required property var modelData
            width: quickLbl.implicitWidth
            height: 18

            Text {
              id: quickLbl
              textFormat: Text.PlainText
              text: modelData.label
              font.family: Style.font.family
              font.pixelSize: 11
              font.weight: modelData.accent ? Font.DemiBold : Font.Normal
              color: quickMouse.containsMouse ? "#ffffff" : (modelData.accent ? "#e8c56b" : Qt.rgba(0.86, 0.89, 0.95, 0.68))
            }

            MouseArea {
              id: quickMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (modelData.action[0] === "lock-preview") root.closeRequested()
                root.runCtlRequested(modelData.action)
              }
            }
          }
        }
      }

      // Segmented Tab Switcher: Appearances | Customize
      Rectangle {
        width: parent.width
        height: 36
        radius: 9
        color: Qt.rgba(1, 1, 1, 0.045)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        Row {
          anchors.fill: parent
          anchors.margins: 3
          spacing: 4

          Repeater {
            model: [
              { id: "appearances", label: "Appearances" },
              { id: "customize", label: "Customize" }
            ]

            Rectangle {
              required property var modelData
              readonly property bool selected: root.activeTab === modelData.id
              width: (parent.width - 4) / 2
              height: parent.height
              radius: 7
              color: selected ? Qt.rgba(0.92, 0.78, 0.42, 0.16) : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
              border.width: selected ? 1 : 0
              border.color: Qt.rgba(0.94, 0.80, 0.44, 0.48)

              Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: modelData.label
                font.family: Style.font.family
                font.pixelSize: 12
                font.weight: selected ? Font.DemiBold : Font.Normal
                color: selected ? "#f6e3a8" : Qt.rgba(0.88, 0.91, 0.96, 0.72)
              }

              MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activeTab = modelData.id
              }
            }
          }
        }
      }
    }

    Rectangle {
      id: topDivider
      anchors.top: headerCol.bottom
      anchors.topMargin: 12
      anchors.left: parent.left
      anchors.right: parent.right
      height: 1
      color: Qt.rgba(1, 1, 1, 0.08)
    }

    // -----------------------------------------------------------------
    // 2. Scrollable Body
    // -----------------------------------------------------------------
    Flickable {
      id: bodyFlick
      anchors.top: topDivider.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: footerCol.top
      contentWidth: width
      contentHeight: root.activeTab === "appearances" ? appearancesTabCol.implicitHeight + 28 : customizeTabCol.implicitHeight + 28
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      // ==================== TAB 1: APPEARANCES ====================
      Column {
        id: appearancesTabCol
        visible: root.activeTab === "appearances"
        width: parent.width - 36
        x: 18
        y: 14
        spacing: 12

        Row {
          width: parent.width
          Text {
            textFormat: Text.PlainText
            text: "Choose an appearance"
            font.family: Style.font.family
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: "#f4f6fa"
            width: parent.width - 68
          }
          Text {
            textFormat: Text.PlainText
            text: "Customize"
            font.family: Style.font.family
            font.pixelSize: 11
            font.weight: Font.Medium
            color: "#e8c56b"
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activeTab = "customize"
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          wrapMode: Text.WordWrap
          lineHeight: 1.25
          text: "Complete combinations of wallpaper, colours, arrival clip, bar style, menu position and desktop pins."
          font.family: Style.font.family
          font.pixelSize: 11
          color: Qt.rgba(0.85, 0.88, 0.94, 0.62)
        }

        // 2-Column Grid of Appearance Cards
        Flow {
          width: parent.width
          spacing: 12

          Repeater {
            model: root.appearancesList

            Item {
              id: cardItem
              required property var modelData
              readonly property bool isCurrent: String(modelData.id || "") === root.activeAppId
              width: Math.floor((appearancesTabCol.width - 12) / 2)
              height: 152

              Column {
                anchors.fill: parent
                spacing: 6

                // Thumbnail Preview Frame
                Rectangle {
                  id: thumbBox
                  width: parent.width
                  height: 102
                  radius: 10
                  color: "#151920"
                  border.width: cardItem.isCurrent ? 1.5 : 1
                  border.color: cardItem.isCurrent ? "#e8c56b" : (cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(1, 1, 1, 0.14))
                  clip: true

                  Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: modelData.previewPath ? Util.fileUrl(String(modelData.previewPath)) : ""
                    sourceSize.width: 240
                    sourceSize.height: 136
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                  }

                  // Dark subtle readability tint
                  Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.18)
                  }

                  // Schematic Top Bar inside thumbnail
                  Item {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 6
                    height: 6

                    // Islands schematic (3 mini capsules)
                    Row {
                      visible: modelData.barStyle === "islands"
                      anchors.fill: parent
                      spacing: (parent.width - 78) / 2
                      Rectangle { width: 22; height: 5; radius: 2.5; color: Qt.rgba(0.1, 0.12, 0.15, 0.82); border.width: 1; border.color: Qt.rgba(1,1,1,0.32) }
                      Rectangle { width: 34; height: 5; radius: 2.5; color: Qt.rgba(0.1, 0.12, 0.15, 0.82); border.width: 1; border.color: Qt.rgba(1,1,1,0.32) }
                      Rectangle { width: 22; height: 5; radius: 2.5; color: Qt.rgba(0.1, 0.12, 0.15, 0.82); border.width: 1; border.color: Qt.rgba(1,1,1,0.32) }
                    }

                    // Full / Glass / Clear schematic
                    Rectangle {
                      visible: modelData.barStyle !== "islands"
                      anchors.fill: parent
                      radius: 2.5
                      color: modelData.barStyle === "clear" ? "transparent" : (modelData.barStyle === "glass" ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0.08, 0.10, 0.13, 0.84))
                      border.width: 1
                      border.color: modelData.barStyle === "clear" ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0.95, 0.82, 0.48, 0.45)
                    }
                  }

                  // Schematic Center OMARCHY Wordmark badge if enabled
                  Text {
                    visible: modelData.showWallpaperLogo === true
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    text: "OMARCHY"
                    font.family: Style.font.family
                    font.pixelSize: 11
                    font.weight: Font.Black
                    font.letterSpacing: 1.2
                    color: modelData.logoStyle === "glacier" ? "#c8e6ff" : (modelData.logoStyle === "aurora" ? "#d9c2ff" : "#f5df9c")
                  }

                  // Schematic Menu Position pill badge
                  Rectangle {
                    height: 15
                    width: menuBadgeTxt.implicitWidth + 10
                    radius: 4
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 16
                    anchors.rightMargin: 6
                    color: Qt.rgba(0.06, 0.08, 0.10, 0.80)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.18)

                    Text {
                      id: menuBadgeTxt
                      textFormat: Text.PlainText
                      anchors.centerIn: parent
                      text: "Menu " + (modelData.menuStyle === "center" ? "centre" : String(modelData.menuStyle || "left"))
                      font.family: Style.font.family
                      font.pixelSize: 9
                      color: "#e6ebf4"
                    }
                  }

                  // Schematic Desktop Pins indicator at bottom
                  Row {
                    spacing: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    x: modelData.pinLayout === "center"
                      ? (parent.width - width) / 2
                      : (modelData.pinLayout === "right" ? parent.width - width - 8 : 8)

                    Rectangle { width: 24; height: 6; radius: 3; color: Qt.rgba(0.08, 0.10, 0.13, 0.82); border.width: 1; border.color: Qt.rgba(1,1,1,0.34) }
                    Rectangle { width: 24; height: 6; radius: 3; color: Qt.rgba(0.08, 0.10, 0.13, 0.82); border.width: 1; border.color: Qt.rgba(1,1,1,0.34) }
                  }

                  // Delete button for custom user-saved appearances
                  Rectangle {
                    visible: modelData.builtin === false
                    width: 18
                    height: 18
                    radius: 9
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 5
                    color: Qt.rgba(0.1, 0.1, 0.12, 0.82)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.22)
                    z: 3

                    Text {
                      textFormat: Text.PlainText
                      anchors.centerIn: parent
                      text: "×"
                      font.pixelSize: 12
                      color: "#f87171"
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: function(mouse) {
                        mouse.accepted = true
                        root.runCtlRequested(["appearance", "delete", String(modelData.id)])
                      }
                    }
                  }

                  MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runCtlRequested(["appearance", "apply", String(modelData.id)])
                  }
                }

                // Title Row
                Row {
                  width: parent.width
                  spacing: 6

                  Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: cardItem.isCurrent ? "#e8c56b" : Qt.rgba(0.75, 0.80, 0.88, 0.45)
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: String(modelData.name || "")
                    font.family: Style.font.family
                    font.pixelSize: 12
                    font.weight: cardItem.isCurrent ? Font.DemiBold : Font.Medium
                    color: cardItem.isCurrent ? "#f8e7b5" : "#f0f3f8"
                    elide: Text.ElideRight
                    width: parent.width - 14
                  }
                }

                // Subtitle
                Text {
                  textFormat: Text.PlainText
                  text: String(modelData.subtitle || "")
                  width: parent.width
                  maximumLineCount: 2
                  wrapMode: Text.WordWrap
                  elide: Text.ElideRight
                  lineHeight: 1.15
                  font.family: Style.font.family
                  font.pixelSize: 10
                  color: Qt.rgba(0.84, 0.88, 0.94, 0.56)
                }
              }
            }
          }
        }
      }

      // ==================== TAB 2: CUSTOMIZE ====================
      Column {
        id: customizeTabCol
        visible: root.activeTab === "customize"
        width: parent.width - 36
        x: 18
        y: 14
        spacing: 16

        // 1. Wallpaper Wordmark (OMARCHY)
        Column {
          width: parent.width
          spacing: 8

          Row {
            width: parent.width
            Text {
              textFormat: Text.PlainText
              text: "Wallpaper Logo (OPT + .)"
              font.family: Style.font.family
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: "#f2f5fa"
              width: parent.width - 68
            }
            Rectangle {
              width: 64
              height: 22
              radius: 11
              color: root.cosmosConfig.showWallpaperLogo !== false ? Qt.rgba(0.92, 0.78, 0.42, 0.22) : Qt.rgba(1, 1, 1, 0.07)
              border.width: 1
              border.color: root.cosmosConfig.showWallpaperLogo !== false ? "#e8c56b" : Qt.rgba(1, 1, 1, 0.16)
              Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: root.cosmosConfig.showWallpaperLogo !== false ? "Shown" : "Hidden"
                font.family: Style.font.family
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: root.cosmosConfig.showWallpaperLogo !== false ? "#f8e7b5" : "#cbd5e1"
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runCtlRequested(["logo", "toggle"])
              }
            }
          }

          Flow {
            width: parent.width
            spacing: 6
            Repeater {
              model: [
                { id: "warm", label: "Warm Gold" },
                { id: "glacier", label: "Glacier" },
                { id: "emerald", label: "Emerald" },
                { id: "aurora", label: "Aurora" },
                { id: "theme", label: "Theme" }
              ]
              ChipButton {
                label: modelData.label
                selected: String(root.cosmosConfig.logoStyle || "warm") === modelData.id
                onClicked: root.runCtlRequested(["logo", "style", modelData.id])
              }
            }
          }

          Flow {
            width: parent.width
            spacing: 6
            Repeater {
              model: [
                { id: "small", label: "Small" },
                { id: "medium", label: "Medium" },
                { id: "large", label: "Large" }
              ]
              ChipButton {
                label: modelData.label
                selected: String(root.cosmosConfig.logoScale || "medium") === modelData.id
                onClicked: root.runCtlRequested(["logo", "scale", modelData.id])
              }
            }
          }
        }

        // 2. Arrival Video Transitions (OWE)
        Column {
          width: parent.width
          spacing: 8

          Text {
            textFormat: Text.PlainText
            text: "Arrival Video Transitions"
            font.family: Style.font.family
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#f2f5fa"
          }

          Flow {
            width: parent.width
            spacing: 6

            ChipButton {
              label: root.introsEnabled ? "Theme Intros: On" : "Theme Intros: Off"
              selected: root.introsEnabled
              onClicked: root.runCtlRequested(["arrival", "toggle"])
            }
            ChipButton {
              label: root.cosmosConfig.arrivalOnUnlock !== false ? "On Unlock: On" : "On Unlock: Off"
              selected: root.cosmosConfig.arrivalOnUnlock !== false
              onClicked: root.runCtlRequested(["arrival", "unlock-toggle"])
            }
            ChipButton {
              label: "▶ Replay Intro"
              selected: false
              onClicked: root.runCtlRequested(["arrival", "play"])
            }
          }
        }

        // 3. Bar Style
        Column {
          width: parent.width
          spacing: 8
          Text {
            textFormat: Text.PlainText
            text: "Top Bar Style (OPT+B)"
            font.family: Style.font.family
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#f2f5fa"
          }
          Flow {
            width: parent.width
            spacing: 6
            Repeater {
              model: [
                { id: "islands", label: "Islands" },
                { id: "frame", label: "Full width" },
                { id: "glass", label: "Glass" },
                { id: "clear", label: "Transparent" }
              ]
              ChipButton {
                label: modelData.label
                selected: String(root.cosmosConfig.barStyle || "frame") === modelData.id
                onClicked: root.runCtlRequested(["bar-style", modelData.id])
              }
            }
          }
        }

        // 4. Menu Position
        Column {
          width: parent.width
          spacing: 8
          Text {
            textFormat: Text.PlainText
            text: "Menu Drawer Position (OPT+E)"
            font.family: Style.font.family
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#f2f5fa"
          }
          Flow {
            width: parent.width
            spacing: 6
            Repeater {
              model: [
                { id: "left", label: "Left" },
                { id: "right", label: "Right" },
                { id: "top", label: "Top" },
                { id: "bottom", label: "Bottom" },
                { id: "center", label: "Centre" }
              ]
              ChipButton {
                label: modelData.label
                selected: String(root.cosmosConfig.menuStyle || "left") === modelData.id
                onClicked: root.runCtlRequested(["menu-style", modelData.id])
              }
            }
          }
        }

        // 5. Desktop Pins
        Column {
          width: parent.width
          spacing: 8
          Text {
            textFormat: Text.PlainText
            text: "Empty-Desktop Pins"
            font.family: Style.font.family
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#f2f5fa"
          }
          Flow {
            width: parent.width
            spacing: 6
            Repeater {
              model: [
                { id: "left", label: "Left (Whisper)" },
                { id: "center", label: "Centre (Horizon)" },
                { id: "right", label: "Right (Cove)" }
              ]
              ChipButton {
                label: modelData.label
                selected: String(root.cosmosConfig.pinLayout || "left") === modelData.id
                onClicked: root.runCtlRequested(["pin-layout", modelData.id])
              }
            }
          }
        }

        // 6. Lock Screen Rain
        Column {
          width: parent.width
          spacing: 8
          Text {
            textFormat: Text.PlainText
            text: "Lock Screen Rain (OPT+R)"
            font.family: Style.font.family
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#f2f5fa"
          }
          Flow {
            width: parent.width
            spacing: 6
            Repeater {
              model: [
                { id: "drizzle", label: "Drizzle" },
                { id: "downpour", label: "Downpour" },
                { id: "clear", label: "Off" }
              ]
              ChipButton {
                label: modelData.label
                selected: String(root.cosmosConfig.rainMode || "drizzle") === modelData.id
                onClicked: root.runCtlRequested(["rain-mode", modelData.id])
              }
            }
          }
        }
      }
    }

    // -----------------------------------------------------------------
    // 3. Sticky Footer: Undo / Keep bar + Save Current Appearance
    // -----------------------------------------------------------------
    Column {
      id: footerCol
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 14
      spacing: 8

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
      }

      // Live "Changes applied · Undo / Keep" bar (live confirmation bar)
      Rectangle {
        visible: root.undoPending
        width: parent.width
        height: 44
        radius: 10
        color: Qt.rgba(0.18, 0.17, 0.13, 0.88)
        border.width: 1
        border.color: Qt.rgba(0.92, 0.78, 0.42, 0.45)

        Row {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 8
          spacing: 8

          Text {
            textFormat: Text.PlainText
            text: "Changes applied"
            font.family: Style.font.family
            font.pixelSize: 12
            font.weight: Font.Medium
            color: "#f4f6fa"
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 126
          }

          Rectangle {
            width: 52
            height: 28
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            color: undoMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              text: "Undo"
              font.family: Style.font.family
              font.pixelSize: 12
              font.weight: Font.Medium
              color: "#e2e8f0"
            }

            MouseArea {
              id: undoMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.runCtlRequested(["appearance", "undo"])
            }
          }

          Rectangle {
            width: 56
            height: 28
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            color: keepMouse.containsMouse ? Qt.rgba(0.92, 0.78, 0.42, 0.36) : Qt.rgba(0.92, 0.78, 0.42, 0.24)
            border.width: 1
            border.color: Qt.rgba(0.95, 0.82, 0.48, 0.55)

            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              text: "Keep"
              font.family: Style.font.family
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: "#fae8b4"
            }

            MouseArea {
              id: keepMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.runCtlRequested(["appearance", "keep"])
            }
          }
        }
      }

      // "Save appearance ›" expandable creator
      Column {
        width: parent.width
        spacing: 6

        Rectangle {
          width: parent.width
          height: 30
          radius: 8
          color: saveToggleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

          Row {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            Text {
              textFormat: Text.PlainText
              text: "Save appearance"
              font.family: Style.font.family
              font.pixelSize: 12
              color: Qt.rgba(0.88, 0.91, 0.96, 0.78)
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 20
            }

            Text {
              textFormat: Text.PlainText
              text: root.saveExpanded ? "⌄" : "›"
              font.family: Style.font.family
              font.pixelSize: 14
              color: Qt.rgba(0.88, 0.91, 0.96, 0.55)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: saveToggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.saveExpanded = !root.saveExpanded
              if (root.saveExpanded) saveInput.forceActiveFocus()
            }
          }
        }

        Row {
          visible: root.saveExpanded
          width: parent.width
          spacing: 8

          Rectangle {
            width: parent.width - 68
            height: 32
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: saveInput.activeFocus ? "#e8c56b" : Qt.rgba(1, 1, 1, 0.16)

            TextInput {
              id: saveInput
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              verticalAlignment: TextInput.AlignVCenter
              color: "#f4f6fa"
              font.family: Style.font.family
              font.pixelSize: 12
              clip: true
              text: "My Cosmos Setup"
              onAccepted: {
                if (text.trim().length > 0) {
                  root.runCtlRequested(["appearance", "save", text.trim()])
                  root.saveExpanded = false
                }
              }
            }
          }

          Rectangle {
            width: 60
            height: 32
            radius: 8
            color: Qt.rgba(0.92, 0.78, 0.42, 0.24)
            border.width: 1
            border.color: "#e8c56b"

            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              text: "Save"
              font.family: Style.font.family
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: "#fae8b4"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (saveInput.text.trim().length > 0) {
                  root.runCtlRequested(["appearance", "save", saveInput.text.trim()])
                  root.saveExpanded = false
                }
              }
            }
          }
        }
      }
    }
  }

  component ChipButton: Rectangle {
    id: chip
    property string label: ""
    property bool selected: false
    signal clicked()

    width: chipTxt.implicitWidth + 20
    height: 26
    radius: 7
    color: selected ? Qt.rgba(0.92, 0.78, 0.42, 0.20) : (chipMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.045))
    border.width: 1
    border.color: selected ? Qt.rgba(0.94, 0.80, 0.44, 0.55) : Qt.rgba(1, 1, 1, 0.12)

    Text {
      id: chipTxt
      textFormat: Text.PlainText
      anchors.centerIn: parent
      text: chip.label
      font.family: Style.font.family
      font.pixelSize: 11
      font.weight: chip.selected ? Font.DemiBold : Font.Normal
      color: chip.selected ? "#fae8b4" : "#dde3ee"
    }

    MouseArea {
      id: chipMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.clicked()
    }
  }
}
