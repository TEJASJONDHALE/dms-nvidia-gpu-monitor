import QtQuick
import Quickshell
import Quickshell.Io

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    
    property real gpuUsage: 0.0
    property real vramUsed: 0.0
    property real vramTotal: 0.0
    property real vramPercent: 0.0
    property int temperature: 0
    property int powerUsage: 0
    property string gpuName: "NVIDIA GPU"
    
    property real gfxUsage: root.gpuUsage
    property real memUsage: 0.0
    property real mediaUsage: 0.0
    
    property int updateInterval: 2000

    Timer {
        id: updateTimer
        interval: root.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateGpuStatsProcess.running = true
    }

    Process {
        id: updateGpuStatsProcess
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,name", "--format=csv,noheader,nounits"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var textClean = text.trim()
                if (textClean === "") return

                var parts = textClean.split(", ")
                
                if (parts.length >= 6) {
                    root.gpuUsage = parseFloat(parts[0]) || 0.0
                    root.vramUsed = parseFloat(parts[1]) || 0.0
                    root.vramTotal = parseFloat(parts[2]) || 0.0
                    root.temperature = parseInt(parts[3]) || 0
                    root.powerUsage = parseInt(parts[4]) || 0
                    root.gpuName = parts[5]

                    if (root.vramTotal > 0) {
                        root.vramPercent = (root.vramUsed / root.vramTotal) * 100
                    }
                    
                    root.gfxUsage = root.gpuUsage
                }
            }
        }
    }
    
    function formatVram() {
        if (root.vramTotal < 1024) {
            return `${root.vramUsed.toFixed(0)}/${root.vramTotal.toFixed(0)} MB`
        } else {
            const usedGB = (root.vramUsed / 1024).toFixed(1)
            const totalGB = (root.vramTotal / 1024).toFixed(1)
            return `${usedGB}/${totalGB} GB`
        }
    }
    
    function getUsageColor(percent) {
        if (percent > 90) return Theme.error
        if (percent > 70) return "#ffa500"
        return Theme.primary
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
                text: `${root.gpuUsage.toFixed(0)}% | ${(root.vramUsed / 1024).toFixed(1)}GB`
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    
    popoutContent: Component {
        PopoutComponent {
            headerText: root.gpuName
            showCloseButton: true
            
            Column {
                width: parent.width
                spacing: Theme.spacingL
                
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    Row {
                        width: parent.width
                        StyledText {
                            width: parent.width - 50
                            text: "GPU Usage"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        StyledText {
                            text: `${root.gpuUsage.toFixed(1)}%`
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 12
                        color: Theme.surfaceText
                        radius: Theme.cornerRadius
                        Rectangle {
                            width: parent.width * (root.gpuUsage / 100)
                            height: parent.height
                            color: root.getUsageColor(root.gpuUsage)
                            radius: Theme.cornerRadius
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                }
                
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    Row {
                        width: parent.width
                        StyledText {
                            width: parent.width - 100
                            text: "VRAM Usage"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        StyledText {
                            text: root.formatVram()
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 12
                        color: Theme.surfaceText
                        radius: Theme.cornerRadius
                        Rectangle {
                            width: parent.width * (root.vramPercent / 100)
                            height: parent.height
                            color: root.getUsageColor(root.vramPercent)
                            radius: Theme.cornerRadius
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                }
                
                Row {
                    width: parent.width
                    spacing: Theme.spacingXL
                    
                    Column {
                        visible: root.temperature > 0
                        spacing: Theme.spacingXS
                        StyledText {
                            text: "Temperature"
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        StyledText {
                            text: `${root.temperature}°C`
                            color: root.temperature > 80 ? Theme.error : Theme.surfaceText
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                        }
                    }
                    
                    Column {
                        visible: root.powerUsage > 0
                        spacing: Theme.spacingXS
                        StyledText {
                            text: "Power"
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        StyledText {
                            text: `${root.powerUsage}W`
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
