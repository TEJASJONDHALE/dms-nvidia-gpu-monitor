# NVIDIA GPU Monitor for DankMaterialShell

A native **NVIDIA** GPU monitoring widget for [DankMaterialShell](https://github.com/DankMaterialShell/DankMaterialShell).

This plugin provides a real-time, animated dashboard for your NVIDIA graphics card, ported from the excellent [AMD GPU Monitor](https://github.com/navidagz/dms-amd-gpu-monitor) by navidagz.

![Screenshot](screenshot.png)


## Requirements

1.  **DankMaterialShell** 
2.  **NVIDIA Drivers**
3.  **nvidia-smi** 

\`\`\`bash
# Arch Linux check
sudo pacman -S nvidia-utils
nvidia-smi  
\`\`\`

## Installation

###1: Clone the repo to plugins directory

1.  Navigate to your DMS plugins directory:
    \`\`\`bash
    cd ~/.config/DankMaterialShell/plugins
    \`\`\`

2.  Clone this repository:
    \`\`\`bash
    git clone https://github.com/TEJASJONDHALE/dms-nvidia-gpu-monitor.git nvidia-gpu-monitor
    \`\`\`

3.  Restart DankMaterialShell:
    \`\`\`bash
    dms restart
    \`\`\`

###2: Enable in Settings

1.  Open **Dank Settings** (\`Super\` + \`Comma\`).
2.  Go to **Plugins** → Click **Scan**.
3.  Find **"NVIDIA GPU Monitor"** in the list and toggle it **ON**.

## Configuration

To add the widget to your bar, edit your \`settings.json\`:

**File:** \`~/.config/DankMaterialShell/settings.json\`

Add \`"nvidiaGpuMonitor"\` to your \`rightWidgets\` (or center/left) list:

\`\`\`json
"rightWidgets": [
    {
        "id": "cpuUsage",
        "enabled": true,
        "minimumWidth": true
    },
    {
        "id": "nvidiaGpuMonitor",
        "enabled": true,
        "minimumWidth": true
    },
    {
        "id": "cpuTemp",
        "enabled": true,
        "minimumWidth": true
    }
]
\`\`\`

## Troubleshooting

### Widget shows "0%" or "--"
* Ensure \`nvidia-smi\` works in your terminal.
* Check if you have multiple GPUs. The plugin currently grabs the *first* NVIDIA GPU found.

### "Plugin not found" in settings
* Ensure the folder name matches the ID expectation or that you have clicked **Scan** in the plugins menu.
* Verify permissions: \`sudo chown -R \$USER:\$USER ~/.config/DankMaterialShell/plugins/\`

## Credits

* [navidagz/dms-amd-gpu-monitor](https://github.com/navidagz/dms-amd-gpu-monitor) 

## License

MIT
EOF
