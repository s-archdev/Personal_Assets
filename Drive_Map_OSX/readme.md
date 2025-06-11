# Drive Storage Heat Map Visualizer for macOS

A powerful terminal-based tool that provides visual heat maps and detailed file listings to help you understand your disk usage patterns on macOS.

## Features

🔥 **Visual Heat Map**: Color-coded grid showing file sizes at a glance  
📊 **Top Files List**: Detailed listing of the largest files and directories  
💾 **Drive Information**: Complete drive usage statistics with visual progress bars  
🎯 **Interactive Selection**: Easy drive selection with usage previews  
⚡ **Fast Scanning**: Efficient directory traversal with progress indicators  
🎨 **Color-Coded Display**: Intuitive color scheme for different file types and sizes  

## Quick Installation

### One-Line Install
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/drive-heatmap/main/install.sh | bash
```

### Manual Installation

1. **Download the installer**:
   ```bash
   curl -O https://raw.githubusercontent.com/yourusername/drive-heatmap/main/install.sh
   chmod +x install.sh
   ./install.sh
   ```

2. **Or install directly**:
   - Save the Python script as `drive-heatmap`
   - Make it executable: `chmod +x drive-heatmap`
   - Move to your PATH: `sudo mv drive-heatmap /usr/local/bin/`

## Requirements

- **macOS** (tested on macOS 10.15+)
- **Python 3.6+** (usually pre-installed on modern macOS)
- **Terminal** with color support

## Usage

### Basic Usage
```bash
# Interactive mode - select drive from menu
drive-heatmap

# Analyze specific drive/directory
drive-heatmap -d /Users

# Analyze external drive
drive-heatmap -d "/Volumes/My External Drive"
```

### Advanced Options
```bash
# Deeper scan with more files shown
drive-heatmap -D 3 -c 50

# Quick scan of root filesystem
drive-heatmap -d / -D 1 -c 10

# Show help
drive-heatmap --help
```

### Command Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--drive` | `-d` | Specify drive/directory path | Interactive selection |
| `--depth` | `-D` | Maximum scan depth | 2 |
| `--count` | `-c` | Number of top files to display | 20 |
| `--help` | `-h` | Show help message | - |

## Output Explanation

### Heat Map Legend
- 🟥 **Red**: Largest files (80-100% of max size)
- 🟪 **Magenta**: Very large files (60-80%)
- 🟨 **Yellow**: Large files (40-60%)
- 🟦 **Cyan**: Medium files (20-40%)
- 🟩 **Green**: Small files (5-20%)
- ⬛ **Gray**: Very small files (<5%)

### File List Colors
- 🔵 **Blue**: Directories
- 🔴 **Red**: Large files (>1GB)
- 🟡 **Yellow**: Medium files (>1MB)
- 🟢 **Green**: Small files (<1MB)

## Example Output

```
╔════════════════════════════════════════╗
║        Drive Storage Heat Map          ║
║          Visualizer for macOS          ║
╚════════════════════════════════════════╝

=== DRIVE INFORMATION ===
Drive: /
Total Space: 500.11 GB
Used Space:  387.45 GB
Free Space:  112.66 GB
Usage:       77.5%
Usage Bar:   ███████████████████████████████░░░░░░░░░

=== STORAGE HEAT MAP ===
Larger files shown in warmer colors (red = largest)

████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████

=== TOP 20 LARGEST FILES/DIRECTORIES ===

#   SIZE         TYPE NAME
──────────────────────────────────────────────────────────────────────
1   45.2 GB     DIR  Applications
    └─ /Applications
2   38.7 GB     DIR  Users
    └─ /Users
3   12.4 GB     DIR  Library
    └─ /Library
4   8.9 GB      FILE movie_backup.mp4
    └─ /Users/username/Downloads/movie_backup.mp4
5   3.2 GB      DIR  System
    └─ /System
```

## Performance Tips

### For Large Drives
- Use `--depth 1` for faster scanning of very large drives
- Use `--count 10` to show fewer results for quicker output

### For Detailed Analysis
- Use `--depth 3` or higher for thorough directory scanning
- Use `--count 50` to see more files in the results

### External Drives
```bash
# List available drives first
ls /Volumes/

# Then analyze specific external drive
drive-heatmap -d "/Volumes/External Drive Name"
```

## Troubleshooting

### Permission Issues
If you encounter permission errors:
```bash
# Run with different depth to avoid system directories
drive-heatmap -d /Users -D 2

# Or scan user directory only
drive-heatmap -d "$HOME"
```

### Python Not Found
If you get "python3: command not found":
```bash
# Install Python via Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install python3

# Or download from python.org
open https://www.python.org/downloads/
```

### Script Not Found After Installation
If `drive-heatmap` command is not found:
```bash
# Check if it's in your PATH
which drive-heatmap

# If installed to local directory, add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Uninstallation

```bash
# Remove from system directory
sudo rm /usr/local/bin/drive-heatmap

# Or remove from local directory
rm ~/.local/bin/drive-heatmap
```

## Security & Privacy

- **No Data Collection**: All analysis is performed locally
- **No Network Access**: Tool works completely offline
- **Read-Only Access**: Only reads file information, never modifies files
- **Respects Permissions**: Skips directories/files without read permission

## Technical Details

- **Language**: Python 3
- **Dependencies**: Standard library only (no external packages required)
- **Performance**: Efficiently handles drives with millions of files
- **Memory Usage**: Minimal memory footprint with streaming file processing
- **Cross-Platform**: Designed specifically for macOS filesystem structure

## Contributing

This tool is designed specifically for macOS. For feature requests or bug reports, please ensure you're running on a supported macOS version and include:

- macOS version (`sw_vers`)
- Python version (`python3 --version`)
- Terminal type (Terminal.app, iTerm2, etc.)
- Error messages or unexpected behavior

## License

MIT License - feel free to modify and distribute as needed.

---

**Happy disk analyzing!** 🔥📊