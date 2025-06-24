#!/bin/bash

# foobar2000 Playlist Recovery Script for macOS
# Enhanced version with better search, analysis, and recovery options

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create output directory for findings
OUTPUT_DIR="$HOME/Desktop/foobar2000_recovery_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo -e "${CYAN}=== foobar2000 Playlist Recovery Tool v2.0 ===${NC}"
echo -e "${BLUE}Enhanced recovery script for macOS${NC}"
echo -e "${YELLOW}Results will be saved to: $OUTPUT_DIR${NC}"
echo

# Define comprehensive foobar2000 locations
FOOBAR_PATHS=(
    "$HOME/Library/Application Support/foobar2000"
    "$HOME/.foobar2000"
    "$HOME/Library/Preferences/foobar2000"
    "$HOME/Documents/foobar2000"
    "$HOME/Music/foobar2000"
    "/Applications/foobar2000.app/Contents/Resources"
    "/Applications/foobar2000.app/Contents/MacOS"
    "$HOME/Library/Caches/foobar2000"
    "$HOME/Library/Saved Application State/foobar2000*"
)

# Function to analyze playlist content
analyze_playlist() {
    local file="$1"
    local output_file="$2"
    
    echo "Analyzing: $(basename "$file")" >> "$output_file"
    echo "Path: $file" >> "$output_file"
    echo "Modified: $(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file")" >> "$output_file"
    echo "Size: $(stat -f%z "$file") bytes" >> "$output_file"
    
    if [[ "$file" == *.fpl ]]; then
        echo "Type: foobar2000 native playlist" >> "$output_file"
        echo "Note: Binary format - use foobar2000 to open" >> "$output_file"
    elif [[ "$file" == *.m3u* ]]; then
        echo "Type: M3U playlist" >> "$output_file"
        local track_count=$(grep -c "^[^#]" "$file" 2>/dev/null || echo "0")
        echo "Estimated tracks: $track_count" >> "$output_file"
        echo "Sample tracks:" >> "$output_file"
        head -20 "$file" | grep -v "^#" | head -5 >> "$output_file" 2>/dev/null
    elif [[ "$file" == *.pls ]]; then
        echo "Type: PLS playlist" >> "$output_file"
        local track_count=$(grep -c "^File[0-9]*=" "$file" 2>/dev/null || echo "0")
        echo "Estimated tracks: $track_count" >> "$output_file"
    fi
    echo "----------------------------------------" >> "$output_file"
    echo >> "$output_file"
}

# Function to search and analyze files
search_and_analyze() {
    local path="$1"
    local results_file="$OUTPUT_DIR/search_results.txt"
    
    if [ -d "$path" ]; then
        echo -e "${GREEN}📁 Checking: $path${NC}"
        echo "=== Searching in: $path ===" >> "$results_file"
        
        # Playlist files
        local playlist_found=false
        while IFS= read -r -d '' file; do
            if [ ! -f "$file" ]; then continue; fi
            playlist_found=true
            echo -e "  ${CYAN}🎵 Found playlist: $(basename "$file")${NC} ($(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file"))"
            analyze_playlist "$file" "$OUTPUT_DIR/playlists_analysis.txt"
            # Copy playlist to recovery folder
            cp "$file" "$OUTPUT_DIR/" 2>/dev/null
        done < <(find "$path" -type f \( -name "*.fpl" -o -name "*.m3u" -o -name "*.m3u8" -o -name "*.pls" \) -print0 2>/dev/null)
        
        # Configuration files
        while IFS= read -r -d '' file; do
            if [ ! -f "$file" ]; then continue; fi
            echo -e "  ${YELLOW}⚙️  Config: $(basename "$file")${NC} ($(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file"))"
            echo "Config file: $file" >> "$OUTPUT_DIR/config_files.txt"
            
            # Extract recent file paths from config
            if grep -q -i "recent\|last\|history" "$file" 2>/dev/null; then
                echo "  ${PURPLE}   → Contains recent file references${NC}"
                grep -i "recent\|last\|history\|\.mp3\|\.m4a\|\.flac" "$file" 2>/dev/null | head -10 >> "$OUTPUT_DIR/recent_paths.txt"
            fi
        done < <(find "$path" -type f \( -name "*.cfg" -o -name "*.conf" -o -name "*.xml" -o -name "*.plist" \) -print0 2>/dev/null)
        
        # Database files
        while IFS= read -r -d '' file; do
            if [ ! -f "$file" ]; then continue; fi
            echo -e "  ${BLUE}🗄️  Database: $(basename "$file")${NC} ($(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file"))"
            echo "Database: $file" >> "$OUTPUT_DIR/databases.txt"
            
            # Try to extract readable content from databases
            if command -v strings >/dev/null 2>&1; then
                strings "$file" | grep -E "\.(mp3|m4a|flac|wav|ogg)" | head -20 >> "$OUTPUT_DIR/db_music_paths.txt" 2>/dev/null
            fi
        done < <(find "$path" -type f \( -name "*.sqlite" -o -name "*.db" -o -name "*.db3" -o -name "*.dat" \) -print0 2>/dev/null)
        
        echo >> "$results_file"
    fi
}

# Main search loop
echo -e "${PURPLE}🔍 Searching foobar2000 data locations...${NC}"
for path in "${FOOBAR_PATHS[@]}"; do
    search_and_analyze "$path"
done

# Advanced system-wide search
echo -e "${PURPLE}🔍 Performing system-wide search...${NC}"
echo "=== System-wide search ===" >> "$OUTPUT_DIR/search_results.txt"

# Search for any foobar2000 related files
find "$HOME" -name "*foobar*" -type f 2>/dev/null | head -50 | while read file; do
    echo -e "  ${CYAN}📄 foobar2000 related: $file${NC}"
    echo "$file" >> "$OUTPUT_DIR/all_foobar_files.txt"
done

# Search for playlist files anywhere
find "$HOME" -type f \( -name "*.fpl" -o -name "*.m3u" -o -name "*.m3u8" -o -name "*.pls" \) 2>/dev/null | head -100 | while read file; do
    if [[ "$file" == *foobar* ]] || [[ "$file" == *playlist* ]] || [[ "$file" == *music* ]]; then
        echo -e "  ${GREEN}🎵 Playlist candidate: $file${NC}"
        analyze_playlist "$file" "$OUTPUT_DIR/all_playlists.txt"
        cp "$file" "$OUTPUT_DIR/found_playlists/" 2>/dev/null || mkdir -p "$OUTPUT_DIR/found_playlists/" && cp "$file" "$OUTPUT_DIR/found_playlists/"
    fi
done

# Analyze recent music activity
echo -e "${PURPLE}🎵 Analyzing recent music activity...${NC}"
{
    echo "=== Recently accessed music files (last 7 days) ==="
    find "$HOME/Music" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.flac" -o -name "*.wav" -o -name "*.ogg" \) -atime -7 2>/dev/null | head -50
    echo
    echo "=== Recently modified music files (last 7 days) ==="
    find "$HOME/Music" -type f \( -name "*.mp3" -o -name "*.m4a" -o -name "*.flac" -o -name "*.wav" -o -name "*.ogg" \) -mtime -7 2>/dev/null | head -50
} > "$OUTPUT_DIR/recent_music_activity.txt"

# Check running processes and recent activity
echo -e "${PURPLE}🔄 Checking application status...${NC}"
{
    echo "=== foobar2000 Process Check ==="
    if pgrep -f "foobar2000" > /dev/null; then
        echo "✅ foobar2000 is currently running (PID: $(pgrep -f foobar2000))"
        echo "✅ You may be able to export current playlist from File > Save Playlist"
    else
        echo "❌ foobar2000 is not currently running"
    fi
    echo
    
    echo "=== Recent Application Usage ==="
    # Check console logs for foobar2000 activity
    log show --predicate 'process == "foobar2000"' --last 1d --style compact 2>/dev/null | head -20
} > "$OUTPUT_DIR/app_status.txt"

# Search for backups
echo -e "${PURPLE}💾 Searching for backup files...${NC}"
{
    echo "=== Backup Files ==="
    find "$HOME" -type f \( -name "*foobar*backup*" -o -name "*foobar*.bak" -o -name "*playlist*backup*" -o -name "*playlist*.bak" \) 2>/dev/null
    echo
    echo "=== Auto-save and Temp Files ==="
    find "/tmp" "$HOME/Library/Caches" -name "*foobar*" -o -name "*playlist*" 2>/dev/null | head -20
} > "$OUTPUT_DIR/backups.txt"

# Generate recovery report
echo -e "${CYAN}📊 Generating recovery report...${NC}"
cat > "$OUTPUT_DIR/RECOVERY_REPORT.md" << EOF
# foobar2000 Playlist Recovery Report
Generated: $(date)

## Summary
This report contains all findings from the foobar2000 playlist recovery scan.

## Files Found
- **Playlists**: Check \`found_playlists/\` folder
- **Configuration**: See \`config_files.txt\`
- **Databases**: See \`databases.txt\`
- **Recent Activity**: See \`recent_music_activity.txt\`

## Recovery Steps
1. **Import Found Playlists**: 
   - Open foobar2000
   - Go to File > Load Playlist
   - Navigate to the found_playlists folder
   - Try importing .fpl, .m3u, or .pls files

2. **Check Recent Paths**:
   - Review \`recent_paths.txt\` for recently played files
   - Use these paths to reconstruct your playlist manually

3. **Database Analysis**:
   - Check \`db_music_paths.txt\` for music file paths from databases
   - These might represent your listening history

## Next Steps
- If no playlists were found, check Time Machine backups
- Look for exported playlists in Documents, Desktop, or Music folders
- Check cloud storage services for synchronized playlists
- Review email for any shared or exported playlists

## Contact
If you need help interpreting these results, the files in this folder contain detailed information about what was found.
EOF

# Final summary
echo
echo -e "${GREEN}=== Recovery Scan Complete ===${NC}"
echo -e "${YELLOW}📁 All results saved to: $OUTPUT_DIR${NC}"
echo
echo -e "${CYAN}Summary of findings:${NC}"
echo -e "  📄 Search results: $OUTPUT_DIR/search_results.txt"
echo -e "  🎵 Found playlists: $OUTPUT_DIR/found_playlists/"
echo -e "  📊 Full report: $OUTPUT_DIR/RECOVERY_REPORT.md"
echo
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Open the recovery folder on your Desktop"
echo -e "  2. Check the found_playlists folder for any recoverable playlists"
echo -e "  3. Read the RECOVERY_REPORT.md for detailed guidance"
echo -e "  4. Try importing any .fpl or .m3u files into foobar2000"
echo
echo -e "${PURPLE}💡 Pro tip: If files were found, back them up immediately!${NC}"