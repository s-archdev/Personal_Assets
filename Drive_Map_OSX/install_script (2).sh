#!/bin/bash

# Drive Storage Heat Map Visualizer - Installation Script for macOS
# This script installs the drive heat map tool system-wide

set -e

SCRIPT_NAME="drive-heatmap"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR="/tmp/drive-heatmap-install"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Drive Heat Map Installer          ║${NC}"
echo -e "${BLUE}║        for macOS Systems               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This installer is designed for macOS only.${NC}"
    exit 1
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not installed.${NC}"
    echo -e "${YELLOW}Please install Python 3 first:${NC}"
    echo "  - Download from https://www.python.org/downloads/"
    echo "  - Or install via Homebrew: brew install python3"
    exit 1
fi

echo -e "${GREEN}✓ Python 3 found: $(python3 --version)${NC}"

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Create the Python script
cat > "$SCRIPT_NAME" << 'EOF'
#!/usr/bin/env python3
"""
Drive Storage Heat Map Visualizer for macOS
A terminal-based tool to visualize disk usage with heat maps and file listings.
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
import math
import time
from collections import defaultdict
import shutil

# ANSI color codes for terminal display
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'
    GRAY = '\033[90m'
    
    # Heat map colors (background)
    BG_RED = '\033[101m'
    BG_GREEN = '\033[102m'
    BG_YELLOW = '\033[103m'
    BG_BLUE = '\033[104m'
    BG_MAGENTA = '\033[105m'
    BG_CYAN = '\033[106m'
    BG_WHITE = '\033[107m'
    BG_GRAY = '\033[100m'

def format_size(size_bytes):
    """Convert bytes to human readable format"""
    if size_bytes == 0:
        return "0B"
    size_name = ["B", "KB", "MB", "GB", "TB", "PB"]
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_name[i]}"

def get_drives():
    """Get list of available drives on macOS"""
    drives = []
    try:
        # Get mounted volumes
        volumes_path = Path('/Volumes')
        if volumes_path.exists():
            for drive in volumes_path.iterdir():
                if drive.is_dir() and not drive.name.startswith('.'):
                    drives.append(str(drive))
        
        # Add root filesystem
        drives.insert(0, '/')
        
        return drives
    except Exception as e:
        print(f"{Colors.RED}Error getting drives: {e}{Colors.END}")
        return ['/']

def get_directory_size(path):
    """Get total size of directory and its contents"""
    total = 0
    try:
        for entry in os.scandir(path):
            if entry.is_file(follow_symlinks=False):
                total += entry.stat().st_size
            elif entry.is_dir(follow_symlinks=False):
                total += get_directory_size(entry.path)
    except (PermissionError, OSError):
        pass
    return total

def scan_drive(drive_path, max_depth=2):
    """Scan drive and return file/directory information"""
    print(f"{Colors.CYAN}Scanning {drive_path}...{Colors.END}")
    
    files_info = []
    directories_info = []
    
    def scan_recursive(path, depth=0):
        if depth > max_depth:
            return
            
        try:
            items = list(os.scandir(path))
            total_items = len(items)
            
            for i, entry in enumerate(items):
                if depth == 0:
                    progress = (i + 1) / total_items * 100
                    print(f"\rProgress: {progress:.1f}% - Scanning: {entry.name[:50]}", end="", flush=True)
                
                try:
                    if entry.is_file(follow_symlinks=False):
                        size = entry.stat().st_size
                        files_info.append({
                            'path': entry.path,
                            'name': entry.name,
                            'size': size,
                            'type': 'file'
                        })
                    elif entry.is_dir(follow_symlinks=False):
                        # Skip system directories that might cause issues
                        if entry.name.startswith('.') and depth == 0:
                            continue
                        if entry.name in ['System', 'private', 'dev', 'proc']:
                            continue
                            
                        size = get_directory_size(entry.path)
                        directories_info.append({
                            'path': entry.path,
                            'name': entry.name,
                            'size': size,
                            'type': 'directory'
                        })
                        
                        if depth < max_depth:
                            scan_recursive(entry.path, depth + 1)
                            
                except (PermissionError, OSError, FileNotFoundError):
                    continue
                    
        except (PermissionError, OSError):
            pass
    
    scan_recursive(drive_path)
    print()  # New line after progress
    
    all_items = files_info + directories_info
    return sorted(all_items, key=lambda x: x['size'], reverse=True)

def get_heat_color(size, max_size):
    """Get color for heat map based on size ratio"""
    if max_size == 0:
        return Colors.BG_GRAY
    
    ratio = size / max_size
    if ratio > 0.8:
        return Colors.BG_RED
    elif ratio > 0.6:
        return Colors.BG_MAGENTA
    elif ratio > 0.4:
        return Colors.BG_YELLOW
    elif ratio > 0.2:
        return Colors.BG_CYAN
    elif ratio > 0.05:
        return Colors.BG_GREEN
    else:
        return Colors.BG_GRAY

def create_heat_map(items, terminal_width=80, terminal_height=20):
    """Create a visual heat map representation"""
    if not items:
        return
    
    print(f"\n{Colors.BOLD}=== STORAGE HEAT MAP ==={Colors.END}")
    print(f"{Colors.YELLOW}Larger files shown in warmer colors (red = largest){Colors.END}\n")
    
    max_size = items[0]['size'] if items else 1
    
    # Calculate grid dimensions
    grid_width = min(terminal_width - 10, 60)
    grid_height = min(terminal_height - 5, 15)
    total_cells = grid_width * grid_height
    
    # Take top items that fit in the grid
    display_items = items[:total_cells]
    
    # Create heat map grid
    for row in range(grid_height):
        line = ""
        for col in range(grid_width):
            cell_index = row * grid_width + col
            if cell_index < len(display_items):
                item = display_items[cell_index]
                color = get_heat_color(item['size'], max_size)
                line += f"{color} {Colors.END}"
            else:
                line += f"{Colors.BG_GRAY} {Colors.END}"
        print(line)
    
    # Legend
    print(f"\n{Colors.BOLD}Legend:{Colors.END}")
    print(f"{Colors.BG_RED} {Colors.END} Largest files (80-100%)")
    print(f"{Colors.BG_MAGENTA} {Colors.END} Very large files (60-80%)")
    print(f"{Colors.BG_YELLOW} {Colors.END} Large files (40-60%)")
    print(f"{Colors.BG_CYAN} {Colors.END} Medium files (20-40%)")
    print(f"{Colors.BG_GREEN} {Colors.END} Small files (5-20%)")
    print(f"{Colors.BG_GRAY} {Colors.END} Very small files (<5%)")

def display_top_files(items, count=20):
    """Display top largest files in a formatted list"""
    print(f"\n{Colors.BOLD}=== TOP {count} LARGEST FILES/DIRECTORIES ==={Colors.END}\n")
    
    if not items:
        print(f"{Colors.RED}No files found.{Colors.END}")
        return
    
    # Header
    print(f"{Colors.BOLD}{'#':<3} {'SIZE':<12} {'TYPE':<4} {'NAME':<50}{Colors.END}")
    print("─" * 70)
    
    for i, item in enumerate(items[:count], 1):
        size_str = format_size(item['size'])
        item_type = "DIR" if item['type'] == 'directory' else "FILE"
        name = item['name'][:47] + "..." if len(item['name']) > 50 else item['name']
        
        # Color coding
        if item['type'] == 'directory':
            color = Colors.BLUE
        else:
            if item['size'] > 1024**3:  # > 1GB
                color = Colors.RED
            elif item['size'] > 1024**2:  # > 1MB
                color = Colors.YELLOW
            else:
                color = Colors.GREEN
        
        print(f"{Colors.WHITE}{i:<3}{Colors.END} {Colors.CYAN}{size_str:<12}{Colors.END} "
              f"{Colors.MAGENTA}{item_type:<4}{Colors.END} {color}{name}{Colors.END}")
        
        # Show full path for top 5 items
        if i <= 5:
            path_display = item['path'][:80] + "..." if len(item['path']) > 80 else item['path']
            print(f"    {Colors.GRAY}└─ {path_display}{Colors.END}")

def get_drive_info(drive_path):
    """Get drive space information"""
    try:
        statvfs = os.statvfs(drive_path)
        total_space = statvfs.f_frsize * statvfs.f_blocks
        free_space = statvfs.f_frsize * statvfs.f_available
        used_space = total_space - free_space
        
        return {
            'total': total_space,
            'used': used_space,
            'free': free_space,
            'usage_percent': (used_space / total_space) * 100 if total_space > 0 else 0
        }
    except Exception as e:
        return None

def display_drive_info(drive_path, drive_info):
    """Display drive information"""
    print(f"\n{Colors.BOLD}=== DRIVE INFORMATION ==={Colors.END}")
    print(f"Drive: {Colors.CYAN}{drive_path}{Colors.END}")
    
    if drive_info:
        print(f"Total Space: {Colors.WHITE}{format_size(drive_info['total'])}{Colors.END}")
        print(f"Used Space:  {Colors.YELLOW}{format_size(drive_info['used'])}{Colors.END}")
        print(f"Free Space:  {Colors.GREEN}{format_size(drive_info['free'])}{Colors.END}")
        print(f"Usage:       {Colors.RED if drive_info['usage_percent'] > 80 else Colors.YELLOW}{drive_info['usage_percent']:.1f}%{Colors.END}")
        
        # Usage bar
        bar_width = 40
        used_width = int((drive_info['usage_percent'] / 100) * bar_width)
        bar = "█" * used_width + "░" * (bar_width - used_width)
        color = Colors.RED if drive_info['usage_percent'] > 80 else Colors.YELLOW if drive_info['usage_percent'] > 60 else Colors.GREEN
        print(f"Usage Bar:   {color}{bar}{Colors.END}")

def select_drive():
    """Interactive drive selection"""
    drives = get_drives()
    
    print(f"\n{Colors.BOLD}Available Drives:{Colors.END}")
    for i, drive in enumerate(drives, 1):
        drive_info = get_drive_info(drive)
        if drive_info:
            usage_info = f" ({format_size(drive_info['used'])}/{format_size(drive_info['total'])} - {drive_info['usage_percent']:.1f}% used)"
        else:
            usage_info = ""
        print(f"{Colors.CYAN}{i}.{Colors.END} {drive}{usage_info}")
    
    while True:
        try:
            choice = input(f"\n{Colors.YELLOW}Select drive (1-{len(drives)}) or 'q' to quit: {Colors.END}")
            if choice.lower() == 'q':
                sys.exit(0)
            
            choice_num = int(choice)
            if 1 <= choice_num <= len(drives):
                return drives[choice_num - 1]
            else:
                print(f"{Colors.RED}Invalid choice. Please select 1-{len(drives)}.{Colors.END}")
        except ValueError:
            print(f"{Colors.RED}Invalid input. Please enter a number or 'q'.{Colors.END}")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Drive Storage Heat Map Visualizer for macOS')
    parser.add_argument('--drive', '-d', help='Drive path to analyze')
    parser.add_argument('--depth', '-D', type=int, default=2, help='Scan depth (default: 2)')
    parser.add_argument('--count', '-c', type=int, default=20, help='Number of top files to show (default: 20)')
    
    args = parser.parse_args()
    
    # Clear screen and show header
    os.system('clear')
    print(f"{Colors.BOLD}{Colors.CYAN}")
    print("╔════════════════════════════════════════╗")
    print("║        Drive Storage Heat Map          ║")
    print("║          Visualizer for macOS          ║")
    print("╚════════════════════════════════════════╝")
    print(f"{Colors.END}")
    
    # Get terminal size
    terminal_size = shutil.get_terminal_size()
    
    # Select drive
    if args.drive:
        if not os.path.exists(args.drive):
            print(f"{Colors.RED}Error: Drive path '{args.drive}' does not exist.{Colors.END}")
            sys.exit(1)
        drive_path = args.drive
    else:
        drive_path = select_drive()
    
    # Get drive information
    drive_info = get_drive_info(drive_path)
    display_drive_info(drive_path, drive_info)
    
    # Scan drive
    start_time = time.time()
    items = scan_drive(drive_path, args.depth)
    scan_time = time.time() - start_time
    
    print(f"\n{Colors.GREEN}Scan completed in {scan_time:.1f} seconds. Found {len(items)} items.{Colors.END}")
    
    if not items:
        print(f"{Colors.RED}No files found on the selected drive.{Colors.END}")
        sys.exit(1)
    
    # Display heat map
    create_heat_map(items, terminal_size.columns, terminal_size.lines)
    
    # Display top files
    display_top_files(items, args.count)
    
    print(f"\n{Colors.BOLD}Analysis complete!{Colors.END}")
    print(f"{Colors.GRAY}Tip: Use --depth to scan deeper, --count to show more files{Colors.END}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Operation cancelled by user.{Colors.END}")
        sys.exit(0)
    except Exception as e:
        print(f"\n{Colors.RED}Error: {e}{Colors.END}")
        sys.exit(1)
EOF

# Make the script executable
chmod +x "$SCRIPT_NAME"

# Check if we need sudo for installation
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Administrator privileges required to install to $INSTALL_DIR${NC}"
    
    # Check if user is in admin group or can use sudo
    if groups | grep -q admin || sudo -n true 2>/dev/null; then
        echo -e "${BLUE}Installing drive-heatmap to $INSTALL_DIR...${NC}"
        sudo cp "$SCRIPT_NAME" "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    else
        echo -e "${RED}Error: Cannot install to $INSTALL_DIR without sudo privileges.${NC}"
        echo -e "${YELLOW}Alternative: Install to user directory${NC}"
        
        # Create local bin directory if it doesn't exist
        LOCAL_BIN="$HOME/.local/bin"
        mkdir -p "$LOCAL_BIN"
        
        cp "$SCRIPT_NAME" "$LOCAL_BIN/"
        chmod +x "$LOCAL_BIN/$SCRIPT_NAME"
        
        echo -e "${GREEN}✓ Installed to $LOCAL_BIN/$SCRIPT_NAME${NC}"
        echo -e "${YELLOW}Note: Add $LOCAL_BIN to your PATH if not already done:${NC}"
        echo -e "${BLUE}  echo 'export PATH=\"$LOCAL_BIN:\$PATH\"' >> ~/.zshrc${NC}"
        echo -e "${BLUE}  source ~/.zshrc${NC}"
        
        INSTALLED_PATH="$LOCAL_BIN/$SCRIPT_NAME"
    fi
else
    # Install without sudo
    cp "$SCRIPT_NAME" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    INSTALLED_PATH="$INSTALL_DIR/$SCRIPT_NAME"
fi

# Clean up
cd /
rm -rf "$TEMP_DIR"

if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo -e "${GREEN}✓ Successfully installed drive-heatmap!${NC}"
    echo -e "${BLUE}You can now run it with: ${YELLOW}drive-heatmap${NC}"
    echo
    echo -e "${BOLD}Usage Examples:${NC}"
    echo -e "${CYAN}  drive-heatmap${NC}                    # Interactive mode"
    echo -e "${CYAN}  drive-heatmap -d /Users${NC}         # Analyze specific directory"
    echo -e "${CYAN}  drive-heatmap -D 3 -c 30${NC}       # Deeper scan, show 30 files"
    echo -e "${CYAN}  drive-heatmap --help${NC}            # Show all options"
    echo
    echo -e "${GREEN}Installation complete! Happy analyzing! 🔥${NC}"
elif [ -f "$LOCAL_BIN/$SCRIPT_NAME" ]; then
    echo -e "${GREEN}✓ Successfully installed drive-heatmap to local directory!${NC}"
    echo -e "${BLUE}Run it with: ${YELLOW}drive-heatmap${NC} (after adding to PATH)"
    echo -e "${BLUE}Or directly: ${YELLOW}$LOCAL_BIN/drive-heatmap${NC}"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi