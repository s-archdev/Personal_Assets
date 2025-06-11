# Drive Storage Heat Map Visualizer 🔥

A terminal-based tool for visualizing disk usage with proportional file size representation. Get a quick visual overview of what's taking up space on your drives!

## Features

- 🗺️ **Visual Heat Map**: ASCII-based heat map showing proportional file sizes
- 📊 **Drive Statistics**: Total, used, and free space information
- 📁 **Top Level Breakdown**: Largest directories and files at the root level
- 📋 **Top 20 Largest Files**: Complete list of the biggest individual files
- 🖥️ **Cross-Platform**: Works on Linux, macOS, and Windows
- 🎯 **Interactive Mode**: Easy drive selection menu
- ⚡ **Fast Scanning**: Configurable depth to balance speed vs detail

## Installation

### Quick Install (Linux/macOS)

```bash
# Download and run the installer
curl -sSL https://raw.githubusercontent.com/your-repo/drivemap/main/install.sh | sudo bash

# Or if you have the files locally:
chmod +x install.sh
sudo ./install.sh
```

### Manual Install

1. Download `drive_heatmap.py`
2. Make it executable: `chmod +x drive_heatmap.py`
3. Copy to your PATH: `sudo cp drive_heatmap.py /usr