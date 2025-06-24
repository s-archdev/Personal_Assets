#!/bin/bash

# Recent Files Finder for macOS
# Usage: ./recent_files.sh [days_back] [output_file]
# Default: 90 days back, output to recent_files.txt

# Set default values
DAYS_BACK=${1:-90}
OUTPUT_FILE=${2:-"recent_files.txt"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Searching for recently opened files (last $DAYS_BACK days)...${NC}"

# Create temporary file for collecting results
TEMP_FILE=$(mktemp)

# Clear the output file
> "$OUTPUT_FILE"

echo "Recent Files Report - Generated on $(date)" >> "$OUTPUT_FILE"
echo "Searching back $DAYS_BACK days" >> "$OUTPUT_FILE"
echo "=================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Function to get shortened path
get_short_path() {
    local full_path="$1"
    local home_path="$HOME"
    
    # Replace home directory with ~
    if [[ "$full_path" == "$home_path"* ]]; then
        echo "~${full_path#$home_path}"
    else
        # Show last 3 directories for system paths
        echo "...$(echo "$full_path" | rev | cut -d'/' -f1-3 | rev)"
    fi
}

# Function to format file info
format_file_info() {
    local file_path="$1"
    local access_time="$2"
    local filename=$(basename "$file_path")
    local short_path=$(get_short_path "$file_path")
    
    printf "%-50s | %-20s | %s\n" "$filename" "$access_time" "$short_path"
}

echo -e "${YELLOW}📋 Checking recent documents from various sources...${NC}"

# 1. Check Recent Items from macOS
echo "=== RECENT DOCUMENTS (macOS Recent Items) ===" >> "$OUTPUT_FILE"
if [ -f "$HOME/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.RecentDocuments.sfl2" ]; then
    # Use sfltool if available (newer macOS versions)
    if command -v sfltool &> /dev/null; then
        sfltool dump "$HOME/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.RecentDocuments.sfl2" 2>/dev/null | \
        grep -E "file://" | \
        head -50 | \
        while read -r line; do
            if [[ "$line" =~ file://([^[:space:]]+) ]]; then
                file_path=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('${BASH_REMATCH[1]}'))" 2>/dev/null)
                if [ -f "$file_path" ]; then
                    access_time=$(stat -f "%Sa" "$file_path" 2>/dev/null)
                    format_file_info "$file_path" "$access_time" >> "$OUTPUT_FILE"
                fi
            fi
        done
    fi
fi
echo "" >> "$OUTPUT_FILE"

# 2. Find recently modified files in common directories
echo "=== RECENTLY MODIFIED FILES ===" >> "$OUTPUT_FILE"
echo -e "${YELLOW}📁 Scanning Documents, Desktop, Downloads...${NC}"

# Common directories to search
SEARCH_DIRS=(
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Downloads"
    "$HOME/Pictures"
    "$HOME/Movies"
    "$HOME/Music"
)

for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -type f \
            -not -path "*/.*" \
            -not -name ".*" \
            -not -name "*.tmp" \
            -not -name "*.cache" \
            -mtime -"$DAYS_BACK" \
            -exec stat -f "%Sm %N" -t "%Y-%m-%d %H:%M" {} \; 2>/dev/null | \
        sort -r | \
        head -20 | \
        while IFS=' ' read -r date time full_path; do
            if [ -f "$full_path" ]; then
                format_file_info "$full_path" "$date $time" >> "$OUTPUT_FILE"
            fi
        done
    fi
done
echo "" >> "$OUTPUT_FILE"

# 3. Check recently accessed files using find with atime
echo "=== RECENTLY ACCESSED FILES ===" >> "$OUTPUT_FILE"
echo -e "${YELLOW}⏰ Finding recently accessed files...${NC}"

# Find files accessed in the last period (this may not work on all systems due to noatime)
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -type f \
            -not -path "*/.*" \
            -not -name ".*" \
            -atime -"$DAYS_BACK" \
            -exec stat -f "%Sa %N" -t "%Y-%m-%d %H:%M" {} \; 2>/dev/null | \
        sort -r | \
        head -15 | \
        while IFS=' ' read -r date time full_path; do
            if [ -f "$full_path" ]; then
                format_file_info "$full_path" "$date $time" >> "$OUTPUT_FILE"
            fi
        done
    fi
done
echo "" >> "$OUTPUT_FILE"

# 4. Check QuickLook thumbnails (indicates recently viewed files)
echo "=== RECENTLY VIEWED FILES (QuickLook) ===" >> "$OUTPUT_FILE"
QUICKLOOK_DIR="$HOME/Library/Caches/com.apple.QuickLook.thumbnailcache/thumbnails.data"
if [ -d "$(dirname "$QUICKLOOK_DIR")" ]; then
    find "$(dirname "$QUICKLOOK_DIR")" -name "*" -type f -mtime -"$DAYS_BACK" 2>/dev/null | \
    head -10 | \
    while read -r file; do
        mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null)
        format_file_info "$file" "$mod_time" "~/Library/Caches/QuickLook/" >> "$OUTPUT_FILE"
    done
fi
echo "" >> "$OUTPUT_FILE"

# 5. Check browser downloads (Chrome and Safari)
echo "=== BROWSER DOWNLOADS ===" >> "$OUTPUT_FILE"
echo -e "${YELLOW}🌐 Checking browser download history...${NC}"

# Chrome downloads
CHROME_HISTORY="$HOME/Library/Application Support/Google/Chrome/Default/History"
if [ -f "$CHROME_HISTORY" ]; then
    # Copy to temp location to avoid lock issues
    cp "$CHROME_HISTORY" "/tmp/chrome_history_temp" 2>/dev/null
    if command -v sqlite3 &> /dev/null; then
        sqlite3 "/tmp/chrome_history_temp" "SELECT target_path, datetime(start_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch', 'localtime') FROM downloads WHERE datetime(start_time/1000000 + (strftime('%s', '1601-01-01')), 'unixepoch') > datetime('now', '-$DAYS_BACK days') ORDER BY start_time DESC LIMIT 10;" 2>/dev/null | \
        while IFS='|' read -r file_path download_time; do
            if [ -f "$file_path" ]; then
                format_file_info "$file_path" "$download_time" >> "$OUTPUT_FILE"
            fi
        done
    fi
    rm -f "/tmp/chrome_history_temp"
fi

# Safari downloads
SAFARI_DOWNLOADS="$HOME/Library/Safari/Downloads.plist"
if [ -f "$SAFARI_DOWNLOADS" ] && command -v plutil &> /dev/null; then
    plutil -p "$SAFARI_DOWNLOADS" 2>/dev/null | \
    grep -E "(DownloadEntryPath|DownloadEntryDateFinished)" | \
    head -20 >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# 6. Application-specific recent files
echo "=== APPLICATION RECENT FILES ===" >> "$OUTPUT_FILE"
echo -e "${YELLOW}📱 Checking application recent files...${NC}"

# TextEdit recent files
TEXTEDIT_PLIST="$HOME/Library/Preferences/com.apple.TextEdit.plist"
if [ -f "$TEXTEDIT_PLIST" ] && command -v plutil &> /dev/null; then
    echo "--- TextEdit Recent Files ---" >> "$OUTPUT_FILE"
    plutil -p "$TEXTEDIT_PLIST" 2>/dev/null | grep -A1 -B1 "RecentDocuments" | head -10 >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Add summary
echo "" >> "$OUTPUT_FILE"
echo "=================================================" >> "$OUTPUT_FILE"
echo "Report generated on: $(date)" >> "$OUTPUT_FILE"
echo "Total unique files found: $(grep -c "|" "$OUTPUT_FILE" 2>/dev/null || echo "Various")" >> "$OUTPUT_FILE"
echo "Search period: Last $DAYS_BACK days" >> "$OUTPUT_FILE"

# Clean up
rm -f "$TEMP_FILE"

echo -e "${GREEN}✅ Report saved to: $OUTPUT_FILE${NC}"
echo -e "${BLUE}📊 Preview of results:${NC}"
echo ""
head -20 "$OUTPUT_FILE"
echo ""
echo -e "${YELLOW}💡 Tip: Use 'cat $OUTPUT_FILE' to view the full report${NC}"
echo -e "${YELLOW}💡 Usage: ./recent_files.sh [days_back] [output_file]${NC}"