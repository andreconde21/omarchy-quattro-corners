import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "andreconde.quattro-corners"
  ipcTarget: "andreconde.quattro-corners"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Every entry here maps to a real action in Service.qml. Labels say what the
  // corner will do, and the toggles are marked as such so the list reads as a
  // set of behaviours rather than plugin ids.
  readonly property var actionOptions: [
    { value: "menu",          label: "Omarchy Menu",         glyph: "󰍜" },
    { value: "notifications", label: "Notifications (toggle)", glyph: "󰂚" },
    { value: "dnd",           label: "Do Not Disturb (toggle)", glyph: "󰂛" },
    { value: "clipboard",     label: "Clipboard History",    glyph: "󰅍" },
    { value: "emojis",        label: "Emoji Picker",         glyph: "󰞅" },
    { value: "lock",          label: "Lock Screen",          glyph: "󰌾" },
    { value: "screen-off",    label: "Turn Display Off",     glyph: "󰐥" },
    { value: "command",       label: "Custom Command…",      glyph: "󰆍" },
    { value: "none",          label: "Nothing",              glyph: "󰇘" }
  ]

  readonly property var corners: [
    { key: "topLeft",     label: "Top Left" },
    { key: "topRight",    label: "Top Right" },
    { key: "bottomLeft",  label: "Bottom Left" },
    { key: "bottomRight", label: "Bottom Right" }
  ]

  property bool cornersEnabled: setting("enabled", true) !== false
  property int dwellMs: Number(setting("dwellMs", 400))
  property int targetSize: Number(setting("targetSize", 24))

  property string topLeftAction: String(setting("topLeftAction", "menu"))
  property string topRightAction: String(setting("topRightAction", "notifications"))
  property string bottomLeftAction: String(setting("bottomLeftAction", "clipboard"))
  property string bottomRightAction: String(setting("bottomRightAction", "dnd"))

  property string topLeftCommand: String(setting("topLeftCommand", ""))
  property string topRightCommand: String(setting("topRightCommand", ""))
  property string bottomLeftCommand: String(setting("bottomLeftCommand", ""))
  property string bottomRightCommand: String(setting("bottomRightCommand", ""))

  // Re-read from shell.json each time the panel opens so it never shows values
  // that another writer (CLI, hand-edit) has since changed.
  onOpenedChanged: if (opened) reload()

  function reload() {
    cornersEnabled = setting("enabled", true) !== false
    dwellMs = Number(setting("dwellMs", 400))
    targetSize = Number(setting("targetSize", 24))
    topLeftAction = String(setting("topLeftAction", "menu"))
    topRightAction = String(setting("topRightAction", "notifications"))
    bottomLeftAction = String(setting("bottomLeftAction", "clipboard"))
    bottomRightAction = String(setting("bottomRightAction", "dnd"))
    topLeftCommand = String(setting("topLeftCommand", ""))
    topRightCommand = String(setting("topRightCommand", ""))
    bottomLeftCommand = String(setting("bottomLeftCommand", ""))
    bottomRightCommand = String(setting("bottomRightCommand", ""))
  }

  // Coerce to a known action before the value is used. An unrecognised string
  // from shell.json would otherwise be echoed verbatim by Dropdown's
  // currentLabel() fallback into an AutoText sink.
  function knownAction(value) {
    var candidate = String(value === undefined || value === null ? "" : value)
    for (var i = 0; i < actionOptions.length; i++)
      if (actionOptions[i].value === candidate) return candidate
    return "none"
  }

  function actionOf(key) {
    if (key === "topLeft") return knownAction(topLeftAction)
    if (key === "topRight") return knownAction(topRightAction)
    if (key === "bottomLeft") return knownAction(bottomLeftAction)
    return knownAction(bottomRightAction)
  }

  function setAction(key, value) {
    if (key === "topLeft") topLeftAction = value
    else if (key === "topRight") topRightAction = value
    else if (key === "bottomLeft") bottomLeftAction = value
    else bottomRightAction = value
    save()
  }

  function commandOf(key) {
    if (key === "topLeft") return topLeftCommand
    if (key === "topRight") return topRightCommand
    if (key === "bottomLeft") return bottomLeftCommand
    return bottomRightCommand
  }

  function setCommand(key, value) {
    if (key === "topLeft") topLeftCommand = value
    else if (key === "topRight") topRightCommand = value
    else if (key === "bottomLeft") bottomLeftCommand = value
    else bottomRightCommand = value
  }

  function optionFor(value) {
    for (var i = 0; i < actionOptions.length; i++)
      if (actionOptions[i].value === value) return actionOptions[i]
    return actionOptions[actionOptions.length - 1]
  }

  function glyphFor(value) { return optionFor(value).glyph }
  function labelFor(value) { return optionFor(value).label }

  // Short label for the corner map, where the full "(toggle)" suffix does not
  // fit inside a quadrant.
  function shortLabelFor(value) {
    return labelFor(value).replace(" (toggle)", "").replace("…", "")
  }

  function save() {
    if (!bar || !bar.shell || typeof bar.shell.updateEntryInline !== "function") return
    bar.shell.updateEntryInline(root.moduleName, {
      id: root.moduleName,
      enabled: root.cornersEnabled,
      dwellMs: root.dwellMs,
      targetSize: root.targetSize,
      topLeftAction: root.topLeftAction,
      topRightAction: root.topRightAction,
      bottomLeftAction: root.bottomLeftAction,
      bottomRightAction: root.bottomRightAction,
      topLeftCommand: root.topLeftCommand,
      topRightCommand: root.topRightCommand,
      bottomLeftCommand: root.bottomLeftCommand,
      bottomRightCommand: root.bottomRightCommand
    })
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰊓"
    fontSize: Style.bar.iconFont
    tooltipText: "Quattro Corners"
    dimmed: !root.cornersEnabled
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(620))

    Flickable {
      anchors.fill: parent
      contentWidth: width
      contentHeight: column.implicitHeight
      clip: true

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        PanelHero {
          width: parent.width
          title: "Quattro Corners"
          meta: root.cornersEnabled
            ? "Push the pointer into a corner and hold " + root.dwellMs + "ms"
            : "Hot corners are off"
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              text: "󰊓"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Toggle {
          width: parent.width
          label: "Hot corners"
          description: "Turn every corner target on or off"
          checked: root.cornersEnabled
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: {
            root.cornersEnabled = !root.cornersEnabled
            root.save()
          }
        }

        PanelSectionHeader {
          width: parent.width
          text: "LAYOUT"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        // A miniature of the screen so the four assignments can be read at a
        // glance instead of inferred from four separate dropdown rows.
        Rectangle {
          width: parent.width
          height: Style.space(112)
          radius: Style.cornerRadius
          color: "transparent"
          border.width: 1
          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
          opacity: root.cornersEnabled ? 1.0 : 0.4

          Grid {
            anchors.fill: parent
            anchors.margins: Style.space(6)
            columns: 2
            rows: 2

            Repeater {
              model: root.corners

              Item {
                id: quadrant
                required property var modelData
                width: (parent.width - Style.space(6)) / 2
                height: (parent.height - Style.space(6)) / 2

                readonly property string cornerAction: root.actionOf(modelData.key)
                readonly property bool alignRight: String(modelData.key).indexOf("Right") !== -1
                readonly property bool alignBottom: String(modelData.key).indexOf("bottom") === 0

                Column {
                  width: quadrant.width
                  spacing: Style.space(2)
                  anchors.top: quadrant.alignBottom ? undefined : parent.top
                  anchors.bottom: quadrant.alignBottom ? parent.bottom : undefined

                  Text {
                    width: parent.width
                    horizontalAlignment: quadrant.alignRight ? Text.AlignRight : Text.AlignLeft
                    text: root.glyphFor(quadrant.cornerAction)
                    color: quadrant.cornerAction === "none" ? root.dim : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.iconLarge
                  }

                  Text {
                    width: parent.width
                    horizontalAlignment: quadrant.alignRight ? Text.AlignRight : Text.AlignLeft
                    text: root.shortLabelFor(quadrant.cornerAction)
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }

        PanelSectionHeader {
          width: parent.width
          text: "CORNER ACTIONS"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Repeater {
          model: root.corners

          Column {
            required property var modelData
            width: parent.width
            spacing: Style.space(4)
            opacity: root.cornersEnabled ? 1.0 : 0.45

            Dropdown {
              width: parent.width
              label: modelData.label
              options: root.actionOptions
              value: root.actionOf(modelData.key)
              foreground: root.foreground
              fontFamily: root.fontFamily
              onChanged: function(v) { root.setAction(modelData.key, v) }
            }

            // Only the corner actually set to "command" shows an input, so the
            // panel does not carry four empty command boxes.
            Row {
              visible: root.actionOf(modelData.key) === "command"
              width: parent.width
              spacing: Style.space(6)

              TextField {
                id: commandField
                width: parent.width - saveCommand.width - Style.space(6)
                text: root.commandOf(modelData.key)
                placeholderText: "Shell command, e.g. omarchy-launch-webapp …"
                foreground: root.foreground
                // Commit on Enter or focus-loss, not per keystroke. Writing every
                // intermediate value meant nudging any other control mid-edit
                // persisted a half-typed command — which the corner would then
                // run. It must only ever run what was actually finished.
                onEditingFinished: { root.setCommand(modelData.key, text); root.save() }
              }

              Button {
                id: saveCommand
                text: "Save"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                tooltipText: "Store this command for " + modelData.label
                onClicked: { root.setCommand(modelData.key, commandField.text); root.save() }
              }
            }
          }
        }

        PanelSectionHeader {
          width: parent.width
          text: "HOLD TIME · " + root.dwellMs + " MS"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        PanelSlider {
          width: parent.width
          bar: root.bar
          minimum: 120
          maximum: 1500
          step: 20
          integer: true
          value: root.dwellMs
          onMoved: function(v) { root.dwellMs = Math.round(v) }
          onReleased: function(v) { root.dwellMs = Math.round(v); root.save() }
        }

        Text {
          width: parent.width
          text: "How long the pointer must rest in the corner before it fires. Raise it if corners trigger by accident."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        PanelSectionHeader {
          width: parent.width
          text: "CORNER SIZE · " + root.targetSize + " PX"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        PanelSlider {
          width: parent.width
          bar: root.bar
          minimum: 8
          maximum: 80
          step: 2
          integer: true
          value: root.targetSize
          onMoved: function(v) { root.targetSize = Math.round(v) }
          onReleased: function(v) { root.targetSize = Math.round(v); root.save() }
        }
      }
    }
  }
}
