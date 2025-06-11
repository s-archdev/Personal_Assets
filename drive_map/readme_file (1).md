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
3. Copy to your PATH: `sudo cp drive_heatmap.py /usr/local/bin/drivemap`

### Windows Install

1. Download `drive_heatmap.py`
2. Rename to `drivemap.py`
3. Place in a directory in your PATH or create a batch file:
```batch
@echo off
python3 "C:\path\to\drivemap.py" %*
```

## Usage

### Interactive Mode
```bash
drivemap
```
This will show you a menu of available drives to select from.

### Direct Path Analysis
```bash
# Analyze specific directory
drivemap /home/username
drivemap /var/log
drivemap C:\Users

# Analyze root filesystem
drivemap /

# Windows drives
drivemap C:\
drivemap D:\
```

### Options
```bash
# Custom scan depth (default: 3)
drivemap --depth 5 /home

# Show help
drivemap --help
```

## Sample Output

```
🔥 Drive Storage Heat Map Visualizer
==================================================

🔍 Scanning drive: /home/user
This may take a moment for large drives...

💾 Drive Statistics:
   Total: 500.0 GB
   Used:  320.5 GB
   Free:  179.5 GB
   Usage: 64.1%

📁 Scanned Size: 45.2 GB
📄 Items Found: 127

🗺️  Storage Heat Map:
==================================================================================
│████████████████████████████████████████████████████████████████████████████████│
│████████████████████████████████████████████████████████████████████████████████│
│████████████████████████████████████████████████████████████████████████████████│
│████████████████████████████████████████████████████████████████████████████████│
│████████████████████████████████████████████████████████████████████████████████│
│██████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░··················································│
==================================================================================

📊 Heat Map Legend:
█ = >20% of total size (Largest files)
▓ = 10-20% of total size (Large files)
▒ = 5-10% of total size (Medium files)
░ = 1-5% of total size (Small files)
· = <1% of total size (Tiny files)

📊 Top Level Breakdown in /home/user:
------------------------------------------------------------
 1. 📁 Videos                                   15.2 GB ( 33.6%)
 2. 📁 Documents                                 8.5 GB ( 18.8%)
 3. 📁 Pictures                                  7.3 GB ( 16.1%)
 4. 📁 Downloads                                 5.8 GB ( 12.8%)
 5. 📁 Music                                     3.2 GB (  7.1%)
 6. 📁 .cache                                    2.1 GB (  4.6%)
 7. 📁 .local                                    1.8 GB (  4.0%)
 8. 📁 Desktop                                 892.5 MB (  1.9%)
 9. 📁 .config                                 456.2 MB (  1.0%)
10. 📄 large_file.iso                          234.7 MB (  0.5%)

📋 Top 20 Largest Individual Files:
--------------------------------------------------------------------------------
 1.      4.2 GB │ .../Videos/movie_collection/action_movie.mkv
 2.      3.8 GB │ .../Videos/movie_collection/sci_fi_movie.mp4
 3.      2.1 GB │ .../Documents/presentation.pptx
 4.      1.9 GB │ .../Pictures/RAW_Photos/IMG_2023_001.cr2
 5.      1.7 GB │ .../Pictures/RAW_Photos/IMG_2023_002.cr2
 6.      1.5 GB │ .../Downloads/software_installer.dmg
 7.      1.2 GB │ .../Videos/personal/vacation_2023.mov
 8.      1.1 GB │ .../Documents/backup.zip
 9.    987.3 MB │ .../Music/lossless_album.flac
10.    856.7 MB │ .../Videos/tutorials/coding_course.mp4
11.    743.2 MB │ .../Pictures/photo_library.db
12.    689.5 MB │ .../Documents/work_project.pdf
13.    567.8 MB │ .../Downloads/game_update.zip
14.    456.3 MB │ .../Music/another_album.m4a
15.    398.1 MB │ .../Videos/clips/compilation.avi
16.    345.6 MB │ .../Documents/research_data.xlsx
17.    298.4 MB │ .../Pictures/edited/final_project.psd
18.    267.9 MB │ .../Downloads/ebook_collection.pdf
19.    234.7 MB │ .../Desktop/large_file.iso
20.    198.3 MB │ .../Music/podcast_archive.mp3

✅ Analysis complete for /home/user
```

## Heat Map Legend

- **█** = >20% of total size (Largest files/directories)
- **▓** = 10-20% of total size (Large files/directories)
- **▒** = 5-10% of total size (Medium files/directories)
- **░** = 1-5% of total size (Small files/directories)
- **·** = <1% of total size (Tiny files/directories)

## Requirements

- Python 3.6 or higher
- No additional dependencies required (uses only standard library)

## How It Works

1. **Scanning**: The tool recursively scans the specified directory up to a configurable depth (default: 3 levels)
2. **Size Calculation**: Calculates total sizes for directories and individual files
3. **Heat Map Generation**: Creates a proportional ASCII representation where larger files/directories occupy more visual space
4. **File Ranking**: Recursively finds and ranks all individual files by size

## Performance Notes

- **Scan Depth**: Lower depth (1-2) = faster scanning, less detail. Higher depth (4-5) = slower scanning, more detail
- **Large Drives**: Scanning entire drives can take time. Consider starting with specific directories
- **Permissions**: Files/directories without read permissions are skipped silently

## Troubleshooting

### Permission Denied Errors
```bash
# Run with appropriate permissions
sudo drivemap /root
sudo drivemap /var/log
```

### Slow Performance
```bash
# Reduce scan depth
drivemap --depth 2 /large/directory
```

### No Drives Detected (Interactive Mode)
The tool looks for common mount points. If your drive isn't detected:
```bash
# Use direct path instead
drivemap /path/to/your/drive
```

## License

MIT License - Feel free to use, modify, and distribute!

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Changelog

### v1.0.0
- Initial release
- ASCII heat map visualization
- Interactive drive selection
- Top 20 largest files listing
- Cross-platform support