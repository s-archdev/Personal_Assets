#!/bin/bash

# foobar2000 Playlist Recovery Script for macOS
# This script searches for foobar2000 configuration files, playlists, and recent activity

echo "=== foobar2000 Playlist Recovery Tool ==="
echo "Searching for foobar2000 data files on macOS..."
echo

# Define common foobar2000 locations on macOS
FOOBAR_PATHS=(
    "$HOME/Library/Application Support/foobar2000"
    "$HOME/.foobar2000"
    "$HOME/Library/Preferences/foobar2000"
    "$HOME/Documents/foobar2000"
    "/Applications/foobar2000.app/Contents/Resources"
)

# Function to search for files with specific extensions
search_files() {
    local path="$1"
    local description="$2"
    
    if [ -d "$path" ]; then
        echo "📁 Checking: $path"
        
        # Look for playlist files
        echo "  🎵 Playlist files (.fpl, .m3u, .m3u8, .pls):"
        find "$path" -type f \( -name "*.fpl" -o -name "*.m3u" -o -name "*.m3u8" -o -name "*.pls" \) 2>/dev/null | while read file; do
            echo "    ✓ Found: $file ($(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file"))"
        done
        
        # Look for configuration files
        echo "  ⚙️  Configuration files:"
        find "$path" -type f \( -name "*.cfg" -o -name "*.conf" -o -name "configuration.xml" -o -name "*.db" \) 2>/dev/null | while read file; do
            echo "    ✓ Found: $file ($(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file"))"
        done
        
        # Look for database files that might contain recent tracks
        echo "  🗄️  Database files:"
        find "$path" -type f \( -name "*.sqlite" -o -name "*.db3" -o -name "playback_statistics.dat" -o -name "recent*" \) 2>/dev/null | while read file; do
            echo "    ✓ Found: $file ($(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file"))"
        done
        
        echo
    fi
}

# Search in common foobar2000 locations
for path in "${FOOBAR_PATHS[@]}"; do
    search_files "$path" "Standard foobar2000 location"
done

# Search for any foobar2000 related files in common locations
echo "🔍 Searching entire system for foobar2000 related files..."
echo "  (This may take a moment...)"

# Search for playlist files anywhere in user directory
find "$HOME" -type f \( -name "*.fpl" -o -name "*foobar*playlist*" \) 2>/dev/null | head -20 | while read file; do
    echo "  📝 Playlist candidate: $file ($(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file"))"
done

# Search for recently modified music files (potential recent plays)
echo
echo "🎵 Recently modified music files (last 7 days):"
find "$HOME/Music" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.flac" -o -name "*.wav" -o -name "*.ogg" \) -mtime -7 2>/dev/null | head -10 | while read file; do
    echo "  ♪ $(basename "$file") - $(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file")"
done

echo
echo "=== Additional Recovery Options ==="
echo

# Check if foobar2000 is currently running
if pgrep -f "foobar2000" > /dev/null; then
    echo "✅ foobar2000 is currently running"
    echo "   You might be able to export your current playlist from the application"
else
    echo "❌ foobar2000 is not currently running"
fi

# Look for backup files
echo
echo "🔄 Searching for backup files:"
find "$HOME" -type f \( -name "*foobar*backup*" -o -name "*playlist*backup*" -o -name "*.bak" \) 2>/dev/null | grep -i foobar | while read file; do
    echo "  💾 Backup candidate: $file"
done

# Check Time Machine if available
if [ -d "/Volumes/Time Machine Backups" ] || [ -d "/System/Volumes/Data/.MobileBackups" ]; then
    echo
    echo "⏰ Time Machine detected - you may be able to restore from:"
    echo "   1. Open Time Machine"
    echo "   2. Navigate to foobar2000 application support folder"
    echo "   3. Look for playlist files from before they were lost"
fi

echo
echo "=== Manual Recovery Tips ==="
echo "1. Check foobar2000's File menu for 'Recent Files' or 'Recent Playlists'"
echo "2. Look in foobar2000 Preferences > Playback > Recent files settings"
echo "3. Check if you have any .m3u or .m3u8 files in your Music folder"
echo "4. Look for exported playlists in Documents or Desktop"
echo "5. If you use streaming services, check if playlists were synced there"
echo
echo "=== Next Steps ==="
echo "If files were found above, you can:"
echo "• Copy playlist files (.fpl, .m3u) to foobar2000's playlist folder"
echo "• Import .m3u files directly into foobar2000"
echo "• Check configuration files for recent file paths"
echo
echo "Script completed. Check the output above for any found files."