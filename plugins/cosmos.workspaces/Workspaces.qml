import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "cosmos.workspaces"

  readonly property int slots: 10

  readonly property var monitor: {
    var window = root.QsWindow.window
    var screen = window ? window.screen : null
    return screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
  }
  readonly property string monitorName: root.monitor ? root.monitor.name : ""

  property var blocks: ({})

  function readBlocks(text) {
    var next = {}
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var fields = lines[i].split("\t")
      if (fields.length >= 3 && fields[1] !== "") next[fields[1]] = parseInt(fields[0], 10)
    }
    root.blocks = next
  }

  FileView {
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/monitor-workspaces"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.readBlocks(text())
    onLoadFailed: root.readBlocks("")
  }

  function blockOf(id) {
    return Math.floor((id - 1) / root.slots)
  }

  function slotOf(id) {
    return (id - 1) % root.slots + 1
  }

  function activeWorkspaceId() {
    return root.monitor && root.monitor.activeWorkspace ? root.monitor.activeWorkspace.id : -1
  }

  readonly property int block: {
    var block = root.blocks[root.monitorName]
    if (block !== undefined) return block
    var active = root.activeWorkspaceId()
    return active > 0 ? root.blockOf(active) : 0
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function workspaceIds() {
    var base = root.block * root.slots
    var ids = [base + 1, base + 2, base + 3, base + 4, base + 5]
    var guests = []
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id <= 0) continue
      if (root.blockOf(id) === root.block) {
        if (ids.indexOf(id) === -1) ids.push(id)
      } else if (values[i].monitor && values[i].monitor.name === root.monitorName) {
        guests.push(id)
      }
    }

    ids.sort(function(left, right) { return left - right })
    guests.sort(function(left, right) { return left - right })
    return ids.concat(guests)
  }

  function dispatch(expression) {
    if (root.bar) root.bar.run("hyprctl dispatch " + Util.shellQuote(expression))
  }

  function focusWorkspace(id) {
    if (root.blockOf(id) === root.block) {
      root.dispatch("o.workspaces.focus(" + root.slotOf(id) + ", \"" + root.monitorName + "\")")
    } else {
      root.dispatch("hl.dsp.focus({ workspace = \"" + id + "\" })")
    }
  }

  property real wheelAccumulator: 0

  function scrollWorkspaces(delta) {
    var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
    root.wheelAccumulator = wheel.remainder
    if (wheel.steps === 0) return

    var ids = root.workspaceIds()
    var index = ids.indexOf(root.activeWorkspaceId())
    if (index === -1) return
    var target = ids[Util.clamp(index - wheel.steps, 0, ids.length - 1)]
    if (target !== ids[index]) root.focusWorkspace(target)
  }

  function cycleLayout() {
    if (!root.bar) return
    var command = "omarchy-hyprland-workspace-layout-toggle"
    if (root.monitor && !root.monitor.focused) {
      command = "hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ monitor = \"" + root.monitorName + "\" })") + " >/dev/null && " + command
    }
    root.bar.run(command)
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event ? String(event.name) : ""
      var switched = name === "workspacev2" && root.monitor !== null && root.monitor.focused
      if (switched || name === "moveworkspacev2" || name === "changeworkspaceid") {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
      }
    }
  }

  ShellIpc {
    target: "omarchy.workspaces"
    function refresh(): void { }
  }

  function dotColor(index, total, shown, occupied) {
    var fg = root.bar ? root.bar.barForeground : Commons.Color.foreground
    var acc = Commons.Color.accent
    if (shown) {
      return Qt.rgba(
        fg.r * 0.55 + acc.r * 0.45,
        fg.g * 0.55 + acc.g * 0.45,
        fg.b * 0.55 + acc.b * 0.45,
        0.95
      )
    }
    var t = total > 1 ? index / (total - 1) : 0
    var r = acc.r * (1 - t * 0.65) + fg.r * (t * 0.65)
    var g = acc.g * (1 - t * 0.65) + fg.g * (t * 0.65)
    var b = acc.b * (1 - t * 0.65) + fg.b * (t * 0.65)
    return Qt.rgba(r, g, b, occupied ? 0.88 : 0.45)
  }

  implicitWidth: root.vertical ? root.barSize : (divider.width + Style.space(8) + grid.implicitWidth + Style.space(4))
  implicitHeight: root.vertical ? (divider.height + Style.space(8) + grid.implicitHeight + Style.space(4)) : root.barSize

  Rectangle {
    id: divider
    width: root.vertical ? Style.space(14) : 1
    height: root.vertical ? 1 : Style.space(14)
    x: root.vertical ? Math.round((parent.width - width) / 2) : Style.space(2)
    y: root.vertical ? Style.space(2) : Math.round((parent.height - height) / 2)
    color: root.bar ? root.bar.barForeground : Commons.Color.foreground
    opacity: 0.22
  }

  GridLayout {
    id: grid
    x: root.vertical ? 0 : (divider.x + divider.width + Style.space(6))
    y: root.vertical ? (divider.y + divider.height + Style.space(6)) : 0
    width: root.vertical ? parent.width : implicitWidth
    height: root.vertical ? implicitHeight : parent.height
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(2)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: wsBtn
        required property int modelData
        required property int index

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool shown: root.monitor !== null && root.monitor.activeWorkspace !== null && root.monitor.activeWorkspace.id === modelData
        readonly property int slot: root.slotOf(modelData)
        readonly property int totalCount: root.workspaceIds().length
        readonly property bool firstGuest: root.blockOf(modelData) !== root.block && index > 0 && root.blockOf(root.workspaceIds()[index - 1]) === root.block

        readonly property real pillLen: shown ? Style.spaceReal(20) : Style.spaceReal(occupied ? 6.5 : 5.5)
        readonly property real pillThick: shown ? Style.spaceReal(7) : Style.spaceReal(occupied ? 6.5 : 5.5)

        Layout.leftMargin: firstGuest && !root.vertical ? Style.space(6) : 0
        Layout.topMargin: firstGuest && root.vertical ? Style.space(6) : 0

        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        tooltipText: "Workspace " + slot
        fixedWidth: root.vertical ? root.barSize : Math.round(pillLen + Style.spaceReal(10))
        fixedHeight: root.vertical ? Math.round(pillLen + Style.spaceReal(10)) : root.barSize

        Behavior on fixedWidth {
          enabled: !Style.reduceMotion
          NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic }
        }
        Behavior on fixedHeight {
          enabled: !Style.reduceMotion
          NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic }
        }

        Rectangle {
          anchors.centerIn: parent
          width: root.vertical ? wsBtn.pillThick : wsBtn.pillLen
          height: root.vertical ? wsBtn.pillLen : wsBtn.pillThick
          radius: Math.min(width, height) / 2
          scale: wsBtn.pressScale
          color: root.dotColor(wsBtn.index, wsBtn.totalCount, wsBtn.shown, wsBtn.occupied)

          Behavior on width {
            enabled: !Style.reduceMotion
            NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic }
          }
          Behavior on height {
            enabled: !Style.reduceMotion
            NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic }
          }
          Behavior on color {
            ColorAnimation { duration: Style.duration(180) }
          }
        }

        onPressed: function() {
          if (shown) root.cycleLayout()
          else root.focusWorkspace(modelData)
        }
        onWheelMoved: function(delta) { root.scrollWorkspaces(delta) }
      }
    }
  }
}
