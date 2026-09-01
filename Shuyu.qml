import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

// 漱玉 Shuyu —— fcitx5/rime 输入法状态小组件
//
// 状态轮询（Quickshell 无通用 DBus 模块，沿用 KeyboardLayout 的 Process+Timer 模式）：
//   fcitx5-remote          → 0/1/2 激活态
//   fcitx5-remote -n       → 当前 fcitx5 输入法名（rime / keyboard-us）
//   Rime1.GetCurrentSchema → 当前 rime 方案（shuyu / shuyu_pinyin）
//   Rime1.IsAsciiMode      → rime 内部西文模式
// 动作：左键 fcitx5-remote -t 切换中英；右键/滚轮 Rime1.SetSchema 切换方案。
BarWidget {
  id: root
  moduleName: "io.github.wy471x.shuyu"

  readonly property string shuangpinId: String(setting("shuangpinSchemaId", "shuyu"))
  readonly property string quanpinId: String(setting("quanpinSchemaId", "shuyu_pinyin"))
  readonly property int pollInterval: Number(setting("pollIntervalMs", 500))

  property int imState: 0        // 0 未运行 / 1 未激活 / 2 激活
  property string imName: ""
  property string schemaId: ""
  property bool asciiMode: false
  property bool refreshPending: false

  readonly property bool chineseOn: imState === 2 && imName === "rime" && !asciiMode
  readonly property string label: chineseOn ? (schemaId === quanpinId ? "全" : "漱") : "EN"
  readonly property string tooltip: {
    if (imState === 0) return "漱玉 Shuyu\nfcitx5 未运行"
    if (imState !== 2) return "漱玉 Shuyu\n当前：英文\n左键切换中文 · 右键切换方案"
    if (asciiMode) return "漱玉 Shuyu\n当前：西文模式\n左键切换中文 · 右键切换方案"
    return "漱玉 Shuyu\n当前：" + (schemaId === quanpinId ? "漱玉·全拼" : "漱玉 · 自然码双拼")
      + "\n左键：中/英 · 右键/滚轮：切换方案\n快捷键：Ctrl+Shift+1 双拼 / Ctrl+Shift+2 全拼"
  }

  function refresh() {
    if (stateProc.running) {
      refreshPending = true
      return
    }
    refreshPending = false
    stateProc.running = true
  }

  function toggleIME() {
    if (!root.bar) return
    root.bar.run("fcitx5-remote -t")
    settleTimer.restart()
  }

  function cycleSchema() {
    if (!root.bar) return
    var next = root.schemaId === root.quanpinId ? root.shuangpinId : root.quanpinId
    root.bar.run("dbus-send --session --type=method_call --dest=org.fcitx.Fcitx5 "
      + "/rime org.fcitx.Fcitx.Rime1.SetSchema string:" + next)
    settleTimer.restart()
  }

  Component.onCompleted: refresh()

  Process {
    id: stateProc
    command: ["/bin/sh", "-c", [
      "fcitx5-remote",
      "fcitx5-remote -n",
      "dbus-send --session --type=method_call --print-reply=literal --dest=org.fcitx.Fcitx5 /rime org.fcitx.Fcitx.Rime1.GetCurrentSchema",
      "dbus-send --session --type=method_call --print-reply=literal --dest=org.fcitx.Fcitx5 /rime org.fcitx.Fcitx.Rime1.IsAsciiMode"
    ].join("; ")]
    onRunningChanged: {
      if (running) {
        stallTimer.restart()
        return
      }
      stallTimer.stop()
      if (root.refreshPending) root.refresh()
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        root.imState = parseInt(lines[0], 10) || 0
        root.imName = String(lines[1] || "").trim()
        root.schemaId = String(lines[2] || "").replace(/^string\s*/, "").trim()
        root.asciiMode = String(lines[3] || "").indexOf("true") !== -1
      }
    }
  }

  Timer {
    id: pollTimer
    interval: root.pollInterval
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  // 动作之后立即回读一次，避免等到下个轮询周期
  Timer {
    id: settleTimer
    interval: 150
    onTriggered: root.refresh()
  }

  // 查询卡死时放弃，让下一个轮询周期通过
  Timer {
    id: stallTimer
    interval: 5000
    onTriggered: {
      stateProc.running = false
      pollTimer.restart()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    fontSize: Style.font.caption
    horizontalMargin: 6
    active: root.chineseOn
    activeColor: "#5f9c7e"
    tooltipText: root.tooltip
    onPressed: function(button) {
      if (button === Qt.RightButton) root.cycleSchema()
      else if (button === Qt.LeftButton) root.toggleIME()
    }
    onWheelMoved: function() { root.cycleSchema() }
  }
}
