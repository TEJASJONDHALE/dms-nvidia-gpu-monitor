import QtQuick
import Quickshell
import Quickshell.Io

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property real gpuUsage: 0
    property real vramUsed: 0
    property real vramTotal: 0
    property real temperature: -1
    property real powerDraw: -1
    property string gpuName: "NVIDIA GPU"
    property var processes: []

    property string gpuState: "loading"
    property int updateInterval: 2000

    readonly property real vramPercent: vramTotal > 0 ? (vramUsed / vramTotal) * 100 : 0

    readonly property string awakeGuard: `
for d in /sys/bus/pci/devices/*; do
  [ "$(cat "$d/vendor" 2>/dev/null)" = 0x10de ] || continue
  case "$(cat "$d/class" 2>/dev/null)" in 0x03*) ;; *) continue ;; esac
  [ "$(cat "$d/power/runtime_status" 2>/dev/null)" = suspended ] && { echo SUSPENDED; exit 0; }
  break
done
`

    function num(str, fallback) {
        const v = parseFloat(str)
        return isNaN(v) ? fallback : v
    }

    function formatMem(mib) {
        return mib >= 1024 ? `${(mib / 1024).toFixed(1)}GB` : `${Math.round(mib)}MB`
    }

    function formatVram() {
        if (vramTotal < 1024)
            return `${Math.round(vramUsed)}/${Math.round(vramTotal)} MB`
        return `${(vramUsed / 1024).toFixed(1)}/${(vramTotal / 1024).toFixed(1)} GB`
    }

    function getUsageColor(percent) {
        if (percent > 90) return Theme.error
        if (percent > 70) return Theme.warning
        return Theme.primary
    }

    function pillLabel() {
        switch (gpuState) {
        case "ok": return `${gpuUsage.toFixed(0)}% | ${formatMem(vramUsed)}`
        case "suspended": return "Asleep"
        case "unavailable": return "N/A"
        default: return "--"
        }
    }

    function parseProcesses(xml) {
        const list = []
        const blockRe = /<process_info>([\s\S]*?)<\/process_info>/g
        let block
        while ((block = blockRe.exec(xml)) !== null) {
            const nameMatch = /<process_name>([^<]*)<\/process_name>/.exec(block[1])
            const memMatch = /<used_memory>\s*([\d.]+)\s*MiB/.exec(block[1])
            list.push({
                name: nameMatch ? nameMatch[1].split("/").pop() : "unknown",
                mem: memMatch ? parseFloat(memMatch[1]) : -1
            })
        }
        list.sort((a, b) => b.mem - a.mem)
        return list.slice(0, 5)
    }

    function refreshProcesses() {
        processesProcess.running = true
    }

    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statsProcess.running = true
        }
    }

    Process {
        id: statsProcess
        command: ["sh", "-c", root.awakeGuard
            + "exec nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,name --format=csv,noheader,nounits"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim()
                if (out.startsWith("SUSPENDED")) {
                    root.gpuState = "suspended"
                    return
                }

                const parts = out.split("\n")[0].split(",").map(s => s.trim())
                if (parts.length < 6) {
                    root.gpuState = "unavailable"
                    return
                }

                root.gpuUsage = root.num(parts[0], 0)
                root.vramUsed = root.num(parts[1], 0)
                root.vramTotal = root.num(parts[2], 0)
                root.temperature = root.num(parts[3], -1)
                root.powerDraw = root.num(parts[4], -1)
                root.gpuName = parts.slice(5).join(", ") || "NVIDIA GPU"
                root.gpuState = "ok"
            }
        }
    }

    // Only run while the popout is visible.
    Process {
        id: processesProcess
        command: ["sh", "-c", root.awakeGuard + "exec nvidia-smi -q -x"]

        stdout: StdioCollector {
            onStreamFinished: root.processes = root.parseProcesses(text)
        }
    }

    component UsageBar: Column {
        id: bar
        property string label: ""
        property string valueText: ""
        property real percent: 0
        property color barColor: Theme.primary

        width: parent.width
        spacing: Theme.spacingS

        Item {
            width: parent.width
            height: labelText.implicitHeight

            StyledText {
                id: labelText
                anchors.left: parent.left
                text: bar.label
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
            }
            StyledText {
                anchors.right: parent.right
                text: bar.valueText
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
            }
        }

        Rectangle {
            width: parent.width
            height: 12
            radius: height / 2
            color: Theme.surfaceVariant

            Rectangle {
                // Below 1% the rounded fill would render as a stray sliver.
                width: bar.percent < 1 ? 0 : Math.max(height, parent.width * Math.min(bar.percent, 100) / 100)
                height: parent.height
                radius: height / 2
                color: bar.barColor
                visible: width > 0

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    component StatItem: Column {
        id: stat
        property string label: ""
        property string value: ""
        property color valueColor: Theme.surfaceText

        spacing: Theme.spacingXS

        StyledText {
            text: stat.label
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }
        StyledText {
            text: stat.value
            color: stat.valueColor
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "shadow"
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: root.pillLabel()
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "shadow"
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                text: root.gpuState === "ok" ? `${root.gpuUsage.toFixed(0)}%` : root.pillLabel()
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: root.gpuName
            showCloseButton: true

            Column {
                id: content
                width: parent.width
                spacing: Theme.spacingL

                Timer {
                    interval: 3000
                    running: content.visible
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: root.refreshProcesses()
                }

                StyledText {
                    visible: root.gpuState !== "ok"
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeMedium
                    text: root.gpuState === "suspended" ? "GPU is asleep (runtime suspended)."
                        : root.gpuState === "loading" ? "Reading GPU stats…"
                        : "GPU unavailable. Check that the NVIDIA driver is loaded and nvidia-smi is installed."
                }

                Column {
                    visible: root.gpuState === "ok"
                    width: parent.width
                    spacing: Theme.spacingL

                    UsageBar {
                        label: "GPU Usage"
                        valueText: `${root.gpuUsage.toFixed(1)}%`
                        percent: root.gpuUsage
                        barColor: root.getUsageColor(root.gpuUsage)
                    }

                    UsageBar {
                        label: "VRAM Usage"
                        valueText: root.formatVram()
                        percent: root.vramPercent
                        barColor: root.getUsageColor(root.vramPercent)
                    }

                    Row {
                        spacing: Theme.spacingXL

                        StatItem {
                            visible: root.temperature >= 0
                            label: "Temperature"
                            value: `${root.temperature.toFixed(0)}°C`
                            valueColor: root.temperature > 80 ? Theme.error : Theme.surfaceText
                        }
                        StatItem {
                            visible: root.powerDraw >= 0
                            label: "Power"
                            value: `${root.powerDraw.toFixed(1)}W`
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Top GPU Processes"
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        StyledText {
                            visible: root.processes.length === 0
                            text: "No active processes"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }

                        Repeater {
                            model: root.processes

                            delegate: Item {
                                id: row
                                required property var modelData

                                width: parent.width
                                height: nameText.implicitHeight

                                StyledText {
                                    id: nameText
                                    anchors.left: parent.left
                                    anchors.right: memText.left
                                    anchors.rightMargin: Theme.spacingM
                                    text: row.modelData.name
                                    elide: Text.ElideRight
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                }
                                StyledText {
                                    id: memText
                                    anchors.right: parent.right
                                    text: row.modelData.mem >= 0 ? root.formatMem(row.modelData.mem) : "--"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
