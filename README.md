# NVIDIA GPU Monitor for DankMaterialShell

A native **NVIDIA** GPU monitoring widget for [DankMaterialShell](https://github.com/DankMaterialShell/DankMaterialShell).

This plugin provides a real-time, animated dashboard for your NVIDIA graphics card, ported from the excellent [AMD GPU Monitor](https://github.com/navidagz/dms-amd-gpu-monitor) by navidagz.

![Screenshot](screenshot.png)

## Requirements

* **DankMaterialShell**
* **NVIDIA Drivers**
* **nvidia-smi**

```bash
# Check if you have the tool installed:
nvidia-smi
```

## Installation

### Method 1: Manual Installation

1. Navigate to your DMS plugins directory:
   ```bash
   cd ~/.config/DankMaterialShell/plugins
   ```

2. Clone this repository:
   ```bash
   git clone https://github.com/TEJASJONDHALE/dms-nvidia-gpu-monitor.git nvidia-gpu-monitor
   ```

3. Restart DankMaterialShell:
   ```bash
   dms restart
   ```

### Method 2: Enable in Settings

1. Open **Dank Settings** (`Super` + `,`).
2. Go to **Plugins** → Click **Scan**.
3. Find **"NVIDIA GPU Monitor"** in the list and toggle it **ON**.

## Configuration

To add the widget to your bar, edit your settings file:

**File:** `~/.config/DankMaterialShell/settings.json`

Add `"nvidiaGpuMonitor"` to your `rightWidgets` list:

```json
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
```

## Troubleshooting

**Widget shows "0%" or "--"**
* Ensure `nvidia-smi` works in your terminal.
* The plugin currently grabs the *first* NVIDIA GPU found.

**"Plugin not found" in settings**
* Ensure the folder name is `nvidia-gpu-monitor`.
* Click **Scan** in the plugins menu.
* Verify permissions:
  ```bash
  sudo chown -R $USER:$USER ~/.config/DankMaterialShell/plugins/
  ```

## Credits

* **Original Code:** [navidagz/dms-amd-gpu-monitor](https://github.com/navidagz/dms-amd-gpu-monitor)
