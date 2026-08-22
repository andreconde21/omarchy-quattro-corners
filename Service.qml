import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
  id: root

  // Injected by the shell host when the service plugin is created.
  property var shell: null
  property var manifest: null

  readonly property string pluginId: "andreconde.quattro-corners"

  // The host injects `shell`, `manifest`, and `pluginRegistry` into service
  // plugins but never `settings` — only bar widgets get that. A service must
  // therefore resolve its own record out of shell.json. Precedence matches
  // shell.updateEntryInline(): the bar layout entry wins over the top-level
  // plugins[] entry, so the panel and the service always read what the panel
  // last wrote. Binding to shell.shellConfig keeps this live, so edits in the
  // panel take effect without restarting the shell.
  readonly property var settings: {
    var config = shell ? shell.shellConfig : null
    if (!config) return ({})

    var layout = config.bar && config.bar.layout ? config.bar.layout : null
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var arr = layout ? layout[sections[s]] : null
      if (!(arr instanceof Array)) continue
      for (var i = 0; i < arr.length; i++)
        if (arr[i] && String(arr[i].id) === root.pluginId) return arr[i]
    }

    var plugins = config.plugins
    if (plugins instanceof Array) {
      for (var j = 0; j < plugins.length; j++)
        if (plugins[j] && String(plugins[j].id) === root.pluginId) return plugins[j]
    }
    return ({})
  }

  function setting(key, fallback) {
    var value = settings ? settings[key] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property int dwellMs: Math.max(120, Math.min(3000, Number(setting("dwellMs", 400))))
  readonly property int targetSize: Math.max(4, Math.min(120, Number(setting("targetSize", 24))))
  readonly property bool cornersEnabled: setting("enabled", true) !== false

  function actionFor(edge) {
    if (edge === "top-left") return String(setting("topLeftAction", "menu"))
    if (edge === "top-right") return String(setting("topRightAction", "notifications"))
    if (edge === "bottom-left") return String(setting("bottomLeftAction", "clipboard"))
    if (edge === "bottom-right") return String(setting("bottomRightAction", "dnd"))
    return "none"
  }

  function commandFor(edge) {
    if (edge === "top-left") return String(setting("topLeftCommand", ""))
    if (edge === "top-right") return String(setting("topRightCommand", ""))
    if (edge === "bottom-left") return String(setting("bottomLeftCommand", ""))
    if (edge === "bottom-right") return String(setting("bottomRightCommand", ""))
    return ""
  }

  // Notification history has no "is it showing" IPC to query, so the toggle is
  // tracked here: first trigger replays history, the next dismisses it. The
  // timer re-arms the open state because toasts expire on their own, and a
  // stale `true` would make the next corner hit silently dismiss nothing.
  property bool historyShown: false

  Timer {
    id: historyReset
    interval: 12000
    repeat: false
    onTriggered: root.historyShown = false
  }

  function run(argv) {
    Quickshell.execDetached(argv)
  }

  function trigger(action, command) {
    switch (String(action)) {
    case "menu":
      run(["omarchy-shell", "shell", "toggle", "omarchy.menu", '{"menu":"root"}'])
      break
    case "notifications":
      if (historyShown) {
        run(["omarchy-shell", "notifications", "dismissAll"])
        historyShown = false
        historyReset.stop()
      } else {
        run(["omarchy-shell", "notifications", "showHistory"])
        historyShown = true
        historyReset.restart()
      }
      break
    case "dnd":
      run(["omarchy-shell", "notifications", "toggleDnd"])
      break
    case "clipboard":
      run(["omarchy-shell", "shell", "toggle", "omarchy.clipboard", "{}"])
      break
    case "emojis":
      run(["omarchy-shell", "shell", "toggle", "omarchy.emojis", "{}"])
      break
    case "lock":
      run(["omarchy-shell", "lock", "lock"])
      break
    case "screen-off":
      // Modern Lua dispatcher first, legacy flat syntax as the fallback.
      run(["sh", "-lc",
        "hyprctl dispatch 'hl.dsp.dpms({ state = \"off\" })' >/dev/null 2>&1"
        + " || hyprctl dispatch dpms off"])
      break
    case "command":
      if (String(command || "").trim() !== "") run(["sh", "-lc", String(command)])
      break
    case "none":
    default:
      break
    }
  }

  Variants {
    model: Quickshell.screens

    Item {
      required property var modelData

      component CornerTarget: PanelWindow {
        id: cornerTarget
        required property var targetScreen
        required property string action
        required property string edge

        readonly property bool armed: root.cornersEnabled && cornerTarget.action !== "none"

        screen: targetScreen
        visible: armed
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "andreconde-quattro-corners-" + edge
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
          top: edge.indexOf("top") === 0
          bottom: edge.indexOf("bottom") === 0
          left: edge.indexOf("left") !== -1
          right: edge.indexOf("right") !== -1
        }

        implicitWidth: root.targetSize
        implicitHeight: root.targetSize

        Timer {
          id: dwell
          interval: root.dwellMs
          repeat: false
          onTriggered: {
            root.trigger(cornerTarget.action, root.commandFor(cornerTarget.edge))
            // Latch until the pointer leaves, so resting in the corner fires
            // once instead of repeating.
            cornerTarget.fired = true
          }
        }

        property bool fired: false

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          onEntered: {
            cornerTarget.fired = false
            if (cornerTarget.armed) dwell.restart()
          }
          onExited: {
            dwell.stop()
            cornerTarget.fired = false
          }
        }
      }

      CornerTarget { targetScreen: modelData; action: root.actionFor("top-left"); edge: "top-left" }
      CornerTarget { targetScreen: modelData; action: root.actionFor("top-right"); edge: "top-right" }
      CornerTarget { targetScreen: modelData; action: root.actionFor("bottom-left"); edge: "bottom-left" }
      CornerTarget { targetScreen: modelData; action: root.actionFor("bottom-right"); edge: "bottom-right" }
    }
  }
}
