#!/bin/bash

# Drive Storage Heat Map Visualizer Installer
# This script installs the drivemap tool globally

set -e

SCRIPT_NAME="drivemap"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR="/tmp/drivemap_install"

echo "🔥 Drive Storage Heat Map Visualizer Installer"
echo "============================================="

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is required but not installed."
    echo "Please install Python 3 and try again."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if we have write permissions
if [ ! -w "$INSTALL_DIR" ]; then
    echo "❌ Error: No write permission to $INSTALL_DIR"
    echo "Please run with sudo: sudo $0"
    exit 1
fi

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Download or copy the main script
echo "📥 Installing drivemap script..."

# If running from the same directory as the Python script
if [ -f "drive_heatmap.py" ]; then
    cp "drive_heatmap.py" "$TEMP_DIR/drivemap"
else
    # Create the script inline (you can also download from a repository)
    cat > "$TEMP_DIR/drivemap" << 'EOF'
#!/usr/bin/env python3
"""
Drive Storage Heat Map Visualizer
A terminal-based tool for visualizing disk usage with proportional file size representation
"""

import os
import sys
import argparse
import math
from collections import defaultdict
from pathlib import Path
import shutil

def get_human_readable_size(size_bytes):
    """Convert bytes to human readable format"""
    if size_bytes == 0:
        return "0B"
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_names[i]}"

def scan_directory(path, max_depth=3, current_depth=0):
    """Recursively scan directory and collect file/folder sizes"""
    items = []
    total_size = 0
    
    try:
        if current_depth >= max_depth:
            # Just get the total size for this directory
            for root, dirs, files in os.walk(path):
                for file in files:
                    try:
                        file_path = os.path.join(root, file)
                        size = os.path.getsize(file_path)
                        total_size += size
                    except (OSError, IOError):
                        continue
            return [{"name": os.path.basename(path), "size": total_size, "path": path, "type": "dir"}], total_size
        
        for item in os.listdir(path):
            item_path = os.path.join(path, item)
            try:
                if os.path.isfile(item_path):
                    size = os.path.getsize(item_path)
                    items.append({
                        "name": item,
                        "size": size,
                        "path": item_path,
                        "type": "file"
                    })
                    total_size += size
                elif os.path.isdir(item_path):
                    sub_items, sub_size = scan_directory(item_path, max_depth, current_depth + 1)
                    if sub_size > 0:
                        items.append({
                            "name": item,
                            "size": sub_size,
                            "path": item_path,
                            "type": "dir"
                        })
                        total_size += sub_size
            except (OSError, IOError, PermissionError):
                continue
                
    except (OSError, IOError, PermissionError):
        pass
    
    return items, total_size

def create_heat_map(items, total_size, width=80, height=20):
    """Create a visual heat map representation of file sizes"""
    if not items or total_size == 0:
        return ["No data to display"]
    
    # Sort items by size (largest first)
    sorted_items = sorted(items, key=lambda x: x['size'], reverse=True)
    
    # Create grid
    grid = [[' ' for _ in range(width)] for _ in range(height)]
    
    # Color/character mapping based on size percentage
    def get_char(percentage):
        if percentage > 20:
            return '█'  # Largest files
        elif percentage > 10:
            return '▓'  # Large files
        elif percentage > 5:
            return '▒'  # Medium files
        elif percentage > 1:
            return '░'  # Small files
        else:
            return '·'  # Tiny files
    
    # Fill grid based on proportional sizes
    total_cells = width * height
    filled_cells = 0
    
    for item in sorted_items:
        if filled_cells >= total_cells:
            break
            
        percentage = (item['size'] / total_size) * 100
        cells_needed = max(1, int((item['size'] / total_size) * total_cells))
        char = get_char(percentage)
        
        # Fill cells
        cells_filled = 0
        for row in range(height):
            for col in range(width):
                if filled_cells >= total_cells or cells_filled >= cells_needed:
                    break
                if grid[row][col] == ' ':
                    grid[row][col] = char
                    filled_cells += 1
                    cells_filled += 1
            if filled_cells >= total_cells or cells_filled >= cells_needed:
                break
    
    # Convert grid to strings
    result = []
    for row in grid:
        result.append(''.join(row))
    
    return result

def get_all_files_recursive(path, file_list):
    """Recursively get all files for the top 20 largest files list"""
    try:
        for item in os.listdir(path):
            item_path = os.path.join(path, item)
            try:
                if os.path.isfile(item_path):
                    size = os.path.getsize(item_path)
                    file_list.append({
                        "name": item,
                        "size": size,
                        "path": item_path,
                        "type": "file"
                    })
                elif os.path.isdir(item_path):
                    get_all_files_recursive(item_path, file_list)
            except (OSError, IOError, PermissionError):
                continue
    except (OSError, IOError, PermissionError):
        pass

def print_legend():
    """Print the legend for the heat map"""
    print("\n📊 Heat Map Legend:")
    print("█ = >20% of total size (Largest files)")
    print("▓ = 10-20% of total size (Large files)")
    print("▒ = 5-10% of total size (Medium files)")
    print("░ = 1-5% of total size (Small files)")
    print("· = <1% of total size (Tiny files)")

def visualize_drive(drive_path):
    """Main function to visualize drive storage"""
    print(f"🔍 Scanning drive: {drive_path}")
    print("This may take a moment for large drives...\n")
    
    # Check if path exists and is accessible
    if not os.path.exists(drive_path):
        print(f"❌ Error: Path '{drive_path}' does not exist!")
        return
    
    if not os.access(drive_path, os.R_OK):
        print(f"❌ Error: No read permission for '{drive_path}'!")
        return
    
    # Get drive info
    try:
        total, used, free = shutil.disk_usage(drive_path)
        print(f"💾 Drive Statistics:")
        print(f"   Total: {get_human_readable_size(total)}")
        print(f"   Used:  {get_human_readable_size(used)}")
        print(f"   Free:  {get_human_readable_size(free)}")
        print(f"   Usage: {(used/total)*100:.1f}%\n")
    except:
        print("⚠️  Could not get drive statistics\n")
    
    # Scan directory structure
    items, total_scanned = scan_directory(drive_path, max_depth=3)
    
    if not items:
        print("❌ No accessible files found!")
        return
    
    print(f"📁 Scanned Size: {get_human_readable_size(total_scanned)}")
    print(f"📄 Items Found: {len(items)}\n")
    
    # Create and display heat map
    print("🗺️  Storage Heat Map:")
    print("=" * 82)
    heat_map = create_heat_map(items, total_scanned)
    for line in heat_map:
        print(f"│{line}│")
    print("=" * 82)
    
    print_legend()
    
    # Show top level breakdown
    print(f"\n📊 Top Level Breakdown in {drive_path}:")
    print("-" * 60)
    sorted_items = sorted(items, key=lambda x: x['size'], reverse=True)
    for i, item in enumerate(sorted_items[:10]):
        percentage = (item['size'] / total_scanned) * 100
        type_icon = "📁" if item['type'] == 'dir' else "📄"
        print(f"{i+1:2}. {type_icon} {item['name'][:40]:40} {get_human_readable_size(item['size']):>10} ({percentage:5.1f}%)")
    
    # Get all files for top 20 largest files
    print(f"\n📋 Top 20 Largest Individual Files:")
    print("-" * 80)
    all_files = []
    get_all_files_recursive(drive_path, all_files)
    
    if all_files:
        largest_files = sorted(all_files, key=lambda x: x['size'], reverse=True)[:20]
        for i, file_info in enumerate(largest_files):
            # Truncate path for display
            display_path = file_info['path']
            if len(display_path) > 50:
                display_path = "..." + display_path[-47:]
            
            print(f"{i+1:2}. {get_human_readable_size(file_info['size']):>10} │ {display_path}")
    else:
        print("No individual files found or accessible.")
    
    print(f"\n✅ Analysis complete for {drive_path}")

def get_available_drives():
    """Get list of available drives/mount points"""
    drives = []
    
    if os.name == 'nt':  # Windows
        for letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':
            drive = f"{letter}:\\"
            if os.path.exists(drive):
                drives.append(drive)
    else:  # Unix-like systems
        # Common mount points
        common_mounts = ['/home', '/usr', '/var', '/tmp', '/opt']
        for mount in common_mounts:
            if os.path.exists(mount) and os.path.ismount(mount):
                drives.append(mount)
        
        # Add root
        drives.append('/')
        
        # Check /mnt and /media for additional mounts
        for base in ['/mnt', '/media']:
            if os.path.exists(base):
                try:
                    for item in os.listdir(base):
                        mount_point = os.path.join(base, item)
                        if os.path.ismount(mount_point):
                            drives.append(mount_point)
                except:
                    pass
    
    return drives

def interactive_drive_selection():
    """Interactive drive selection menu"""
    drives = get_available_drives()
    
    if not drives:
        print("❌ No drives detected!")
        return None
    
    print("🗂️  Available Drives/Mount Points:")
    print("-" * 40)
    for i, drive in enumerate(drives):
        try:
            total, used, free = shutil.disk_usage(drive)
            usage_percent = (used / total) * 100
            print(f"{i+1:2}. {drive:15} ({get_human_readable_size(total):>8}, {usage_percent:4.1f}% used)")
        except:
            print(f"{i+1:2}. {drive:15} (Size unavailable)")
    
    print(f"{len(drives)+1:2}. Custom path...")
    
    while True:
        try:
            choice = input(f"\nSelect drive (1-{len(drives)+1}): ").strip()
            
            if choice == str(len(drives)+1):
                custom_path = input("Enter custom path: ").strip()
                if custom_path and os.path.exists(custom_path):
                    return custom_path
                else:
                    print("❌ Invalid path!")
                    continue
            
            choice_num = int(choice) - 1
            if 0 <= choice_num < len(drives):
                return drives[choice_num]
            else:
                print(f"❌ Please enter a number between 1 and {len(drives)+1}")
        except ValueError:
            print("❌ Please enter a valid number")
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            return None

def main():
    parser = argparse.ArgumentParser(
        description="Drive Storage Heat Map Visualizer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                    # Interactive mode
  %(prog)s /home             # Analyze /home directory
  %(prog)s C:\\              # Analyze C: drive (Windows)
        """
    )
    parser.add_argument('path', nargs='?', help='Path to analyze (optional, will prompt if not provided)')
    parser.add_argument('--depth', type=int, default=3, help='Maximum scan depth (default: 3)')
    
    args = parser.parse_args()
    
    print("🔥 Drive Storage Heat Map Visualizer")
    print("=" * 50)
    
    if args.path:
        target_path = args.path
    else:
        target_path = interactive_drive_selection()
    
    if target_path:
        visualize_drive(target_path)
    else:
        print("👋 No drive selected. Exiting.")

if __name__ == "__main__":
    main()
EOF
fi

# Make executable
chmod +x "$TEMP_DIR/drivemap"

# Copy to install directory
cp "$TEMP_DIR/drivemap" "$INSTALL_DIR/"

echo "✅ Successfully installed drivemap to $INSTALL_DIR"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Usage:"
echo "  drivemap                 # Interactive mode"
echo "  drivemap /path/to/scan   # Direct path"
echo "  drivemap --help          # Show help"
echo ""
echo "Try running: drivemap"
