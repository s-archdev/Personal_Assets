#!/usr/bin/env python3
"""
Mac Music History Extractor
Extracts recently played music files from macOS system databases and logs.
Usage: python3 music_history.py [--months N] [--output FILE]
"""

import os
import sys
import sqlite3
import subprocess
import json
import argparse
from datetime import datetime, timedelta
from pathlib import Path
import plistlib

class MacMusicHistoryExtractor:
    def __init__(self, months_back=6):
        self.months_back = months_back
        self.cutoff_date = datetime.now() - timedelta(days=30 * months_back)
        self.music_files = []
        
    def get_itunes_history(self):
        """Extract history from iTunes/Music app database"""
        try:
            # iTunes/Music app database location
            music_db_path = os.path.expanduser("~/Music/Music/Music Library.musiclibrary/music.sqlite")
            
            if not os.path.exists(music_db_path):
                # Try alternative path for older iTunes
                music_db_path = os.path.expanduser("~/Music/iTunes/iTunes Library.itl")
                if not os.path.exists(music_db_path):
                    print("iTunes/Music database not found")
                    return
            
            # Connect to SQLite database
            conn = sqlite3.connect(music_db_path)
            cursor = conn.cursor()
            
            # Query for recently played tracks
            query = """
            SELECT 
                media_item.title,
                media_item.artist,
                media_item.location,
                media_item.date_modified,
                media_item.play_count_recent,
                media_item.date_played
            FROM media_item 
            WHERE media_item.location IS NOT NULL 
            AND media_item.date_played > ?
            ORDER BY media_item.date_played DESC
            """
            
            cursor.execute(query, (self.cutoff_date.timestamp(),))
            results = cursor.fetchall()
            
            for row in results:
                title, artist, location, date_modified, play_count, date_played = row
                if location and os.path.exists(location):
                    self.music_files.append({
                        'title': title or 'Unknown',
                        'artist': artist or 'Unknown',
                        'location': location,
                        'last_played': datetime.fromtimestamp(date_played) if date_played else None,
                        'source': 'iTunes/Music'
                    })
            
            conn.close()
            print(f"Found {len(results)} tracks from iTunes/Music")
            
        except Exception as e:
            print(f"Error accessing iTunes/Music database: {e}")
    
    def get_quicktime_history(self):
        """Extract history from QuickTime/system media logs"""
        try:
            # Check system logs for media file access
            cmd = [
                'log', 'show',
                '--predicate', 'subsystem == "com.apple.quicktime" OR subsystem == "com.apple.avfoundation"',
                '--start', self.cutoff_date.strftime('%Y-%m-%d'),
                '--style', 'json'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    if line.startswith('{'):
                        try:
                            log_entry = json.loads(line)
                            message = log_entry.get('eventMessage', '')
                            
                            # Look for file paths in log messages
                            if any(ext in message.lower() for ext in ['.mp3', '.m4a', '.wav', '.flac', '.aac']):
                                timestamp = log_entry.get('timestamp')
                                if timestamp:
                                    date_played = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                                    
                                    # Extract file path from message
                                    import re
                                    path_match = re.search(r'(/[^\s]+\.(?:mp3|m4a|wav|flac|aac))', message, re.IGNORECASE)
                                    if path_match:
                                        file_path = path_match.group(1)
                                        if os.path.exists(file_path):
                                            self.music_files.append({
                                                'title': os.path.basename(file_path),
                                                'artist': 'Unknown',
                                                'location': file_path,
                                                'last_played': date_played,
                                                'source': 'System Logs'
                                            })
                        except json.JSONDecodeError:
                            continue
            
        except Exception as e:
            print(f"Error accessing system logs: {e}")
    
    def get_recent_files_from_spotlight(self):
        """Use Spotlight to find recently accessed music files"""
        try:
            music_extensions = ['mp3', 'm4a', 'wav', 'flac', 'aac', 'mp4', 'mov']
            
            for ext in music_extensions:
                cmd = [
                    'mdfind',
                    f'kMDItemContentType == "audio/{ext}" OR kMDItemContentType == "public.audio"',
                    '-onlyin', os.path.expanduser('~/')
                ]
                
                result = subprocess.run(cmd, capture_output=True, text=True)
                
                if result.returncode == 0:
                    files = result.stdout.strip().split('\n')
                    
                    for file_path in files:
                        if file_path and os.path.exists(file_path):
                            # Get file modification/access time
                            stat = os.stat(file_path)
                            access_time = datetime.fromtimestamp(stat.st_atime)
                            
                            if access_time >= self.cutoff_date:
                                self.music_files.append({
                                    'title': os.path.basename(file_path),
                                    'artist': 'Unknown',
                                    'location': file_path,
                                    'last_played': access_time,
                                    'source': 'Spotlight'
                                })
            
        except Exception as e:
            print(f"Error using Spotlight search: {e}")
    
    def get_browser_media_history(self):
        """Extract music files played in browsers"""
        try:
            # Chrome history
            chrome_history = os.path.expanduser("~/Library/Application Support/Google/Chrome/Default/History")
            if os.path.exists(chrome_history):
                # Make a copy to avoid locking issues
                subprocess.run(['cp', chrome_history, '/tmp/chrome_history_copy'])
                
                conn = sqlite3.connect('/tmp/chrome_history_copy')
                cursor = conn.cursor()
                
                query = """
                SELECT url, title, last_visit_time 
                FROM urls 
                WHERE (url LIKE '%.mp3%' OR url LIKE '%.m4a%' OR url LIKE '%.wav%')
                AND last_visit_time > ?
                ORDER BY last_visit_time DESC
                """
                
                # Chrome uses microseconds since 1601-01-01
                chrome_cutoff = int((self.cutoff_date - datetime(1601, 1, 1)).total_seconds() * 1000000)
                cursor.execute(query, (chrome_cutoff,))
                
                results = cursor.fetchall()
                for url, title, visit_time in results:
                    # Convert Chrome timestamp
                    last_played = datetime(1601, 1, 1) + timedelta(microseconds=visit_time)
                    
                    self.music_files.append({
                        'title': title or os.path.basename(url),
                        'artist': 'Unknown',
                        'location': url,
                        'last_played': last_played,
                        'source': 'Chrome Browser'
                    })
                
                conn.close()
                os.remove('/tmp/chrome_history_copy')
                
        except Exception as e:
            print(f"Error accessing browser history: {e}")
    
    def remove_duplicates(self):
        """Remove duplicate entries based on file location"""
        seen = set()
        unique_files = []
        
        for file_info in self.music_files:
            location = file_info['location']
            if location not in seen:
                seen.add(location)
                unique_files.append(file_info)
        
        self.music_files = unique_files
    
    def sort_by_date(self):
        """Sort files by last played date (most recent first)"""
        self.music_files.sort(key=lambda x: x['last_played'] or datetime.min, reverse=True)
    
    def extract_all(self):
        """Run all extraction methods"""
        print("Extracting music history from various sources...")
        print(f"Looking for files played in the last {self.months_back} months")
        print(f"Cutoff date: {self.cutoff_date.strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        self.get_itunes_history()
        self.get_quicktime_history()
        self.get_recent_files_from_spotlight()
        self.get_browser_media_history()
        
        self.remove_duplicates()
        self.sort_by_date()
        
        print(f"\nTotal unique music files found: {len(self.music_files)}")
        return self.music_files
    
    def export_to_file(self, output_file):
        """Export results to a file"""
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(f"Music Files History Report\n")
                f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Period: Last {self.months_back} months\n")
                f.write(f"Total files: {len(self.music_files)}\n")
                f.write("=" * 80 + "\n\n")
                
                for i, file_info in enumerate(self.music_files, 1):
                    f.write(f"{i:4d}. {file_info['title']}\n")
                    f.write(f"      Artist: {file_info['artist']}\n")
                    f.write(f"      Location: {file_info['location']}\n")
                    f.write(f"      Last Played: {file_info['last_played'].strftime('%Y-%m-%d %H:%M:%S') if file_info['last_played'] else 'Unknown'}\n")
                    f.write(f"      Source: {file_info['source']}\n")
                    f.write("\n")
            
            print(f"Results exported to: {output_file}")
            
        except Exception as e:
            print(f"Error exporting to file: {e}")
    
    def print_results(self):
        """Print results to console"""
        if not self.music_files:
            print("No music files found in the specified time period.")
            return
        
        print(f"\n{'#':<4} {'Title':<40} {'Last Played':<20} {'Source':<15}")
        print("-" * 100)
        
        for i, file_info in enumerate(self.music_files[:50], 1):  # Show top 50
            title = file_info['title'][:37] + "..." if len(file_info['title']) > 40 else file_info['title']
            date_str = file_info['last_played'].strftime('%Y-%m-%d %H:%M') if file_info['last_played'] else 'Unknown'
            
            print(f"{i:<4} {title:<40} {date_str:<20} {file_info['source']:<15}")
        
        if len(self.music_files) > 50:
            print(f"\n... and {len(self.music_files) - 50} more files")
        
        print(f"\nTo see full details including file paths, use --output option")

def main():
    parser = argparse.ArgumentParser(description='Extract recently played music files from macOS')
    parser.add_argument('--months', type=int, default=6, help='Number of months to look back (default: 6)')
    parser.add_argument('--output', type=str, help='Output file path (optional)')
    parser.add_argument('--format', choices=['text', 'json', 'csv'], default='text', help='Output format')
    
    args = parser.parse_args()
    
    # Check if running on macOS
    if sys.platform != 'darwin':
        print("This tool is designed for macOS only.")
        sys.exit(1)
    
    extractor = MacMusicHistoryExtractor(months_back=args.months)
    results = extractor.extract_all()
    
    if args.output:
        if args.format == 'json':
            import json
            with open(args.output, 'w') as f:
                json.dump([{
                    'title': r['title'],
                    'artist': r['artist'],
                    'location': r['location'],
                    'last_played': r['last_played'].isoformat() if r['last_played'] else None,
                    'source': r['source']
                } for r in results], f, indent=2)
        elif args.format == 'csv':
            import csv
            with open(args.output, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(['Title', 'Artist', 'Location', 'Last Played', 'Source'])
                for r in results:
                    writer.writerow([
                        r['title'], r['artist'], r['location'],
                        r['last_played'].isoformat() if r['last_played'] else '',
                        r['source']
                    ])
        else:
            extractor.export_to_file(args.output)
    else:
        extractor.print_results()

if __name__ == "__main__":
    main()
