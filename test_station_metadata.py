#!/usr/bin/env python3
"""
Radio Station Metadata Test Script

This script tests all radio stations to see which ones provide song title metadata.
It checks both RadCap and SomaFM stations and attempts to fetch current song information.
"""

import json
import requests
import re
import time
import sys
from urllib.parse import urljoin, urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

# Thread-local storage for progress tracking
thread_local = threading.local()

class MetadataChecker:
    def __init__(self):
        self.results = {
            'working': [],
            'no_metadata': [],
            'failed': [],
            'total_tested': 0
        }
        self.lock = threading.Lock()
        
    def print_progress(self, current, total, station_name):
        """Print progress with current station being tested"""
        percent = (current / total) * 100
        bar_length = 30
        filled_length = int(bar_length * current // total)
        bar = '█' * filled_length + '-' * (bar_length - filled_length)
        print(f'\r[{bar}] {percent:.1f}% ({current}/{total}) Testing: {station_name[:40]:<40}', end='', flush=True)

    def test_radcap_station(self, station, category_name):
        """Test a RadCap station for metadata"""
        station_name = station['name']
        station_path = station['path']
        
        try:
            # RadCap stations use a direct playback history URL pattern
            # Try all possible path numbers systematically
            for path_num in [1, 2, 3, 4, 5, 6]:
                try:
                    # Direct approach: try the playback history PHP endpoint
                    playback_url = f"http://radcap.ru/playback-history/{path_num}/{station_path}-ph.php"
                    response = requests.get(playback_url, timeout=15)
                    
                    if response.status_code == 200:
                        # Check if we got actual playback data (not an error page)
                        if len(response.text) > 100 and '<table' in response.text.lower():
                            
                            # Enhanced patterns to find current song information
                            patterns = [
                                # Pattern 1: Standard current song format
                                r'<td[^>]*>([^<]+)</td>\s*<td[^>]*><b>Current Song</b></td>',
                                # Pattern 2: Time + song format
                                r'<td[^>]*>\d{2}:\d{2}:\d{2}</td>\s*<td[^>]*>([^<]+)</td>',
                                # Pattern 3: Most recent entry (first data row)
                                r'<tr[^>]*>\s*<td[^>]*>\d{2}:\d{2}:\d{2}</td>\s*<td[^>]*>([^<]+)</td>',
                                # Pattern 4: Any cell with song-like content
                                r'<td[^>]*>([^<]{10,})</td>',
                            ]
                            
                            for pattern in patterns:
                                matches = re.findall(pattern, response.text, re.IGNORECASE | re.DOTALL)
                                if matches:
                                    # Process each match to find valid song info
                                    for match in matches:
                                        song_info = match.strip()
                                        # Clean up the song info
                                        song_info = re.sub(r'^\s*\d{2}:\d{2}:\d{2}\s*', '', song_info)  # Remove timestamps
                                        song_info = re.sub(r'<[^>]+>', '', song_info)  # Remove HTML tags
                                        song_info = re.sub(r'\s+', ' ', song_info)  # Normalize whitespace
                                        
                                        # Check if this looks like valid song information
                                        if (song_info and 
                                            len(song_info) > 5 and 
                                            song_info.lower() not in ['unknown', 'current song', 'time', 'song'] and
                                            not re.match(r'^\d+$', song_info) and  # Not just numbers
                                            not song_info.startswith('http')):  # Not URLs
                                            
                                            return {
                                                'station': station_name,
                                                'category': category_name,
                                                'path': station_path,
                                                'status': 'working',
                                                'metadata': song_info,
                                                'method': f'radcap_direct_path_{path_num}'
                                            }
                            
                            # If we found the page but no valid song data
                            return {
                                'station': station_name,
                                'category': category_name,
                                'path': station_path,
                                'status': 'no_metadata',
                                'metadata': 'Playback history found but no song data',
                                'method': f'radcap_direct_path_{path_num}'
                            }
                    
                except requests.RequestException as e:
                    continue  # Try next path number
            
            # Alternative approach: try the station HTML page
            try:
                station_url = f"http://radcap.ru/{station_path}.html"
                response = requests.get(station_url, timeout=15)
                
                if response.status_code == 200:
                    # Look for playback-html link
                    playback_matches = re.findall(r'href="([^"]*playback[^"]*\.php[^"]*)"', response.text, re.IGNORECASE)
                    
                    for playback_link in playback_matches:
                        try:
                            full_playback_url = f"http://radcap.ru/{playback_link}" if not playback_link.startswith('http') else playback_link
                            playback_response = requests.get(full_playback_url, timeout=15)
                            
                            if playback_response.status_code == 200 and len(playback_response.text) > 100:
                                # Apply same pattern matching as above
                                patterns = [
                                    r'<td[^>]*>([^<]+)</td>\s*<td[^>]*><b>Current Song</b></td>',
                                    r'<td[^>]*>\d{2}:\d{2}:\d{2}</td>\s*<td[^>]*>([^<]+)</td>',
                                    r'<tr[^>]*>\s*<td[^>]*>\d{2}:\d{2}:\d{2}</td>\s*<td[^>]*>([^<]+)</td>',
                                ]
                                
                                for pattern in patterns:
                                    matches = re.findall(pattern, playback_response.text, re.IGNORECASE | re.DOTALL)
                                    if matches:
                                        for match in matches:
                                            song_info = match.strip()
                                            song_info = re.sub(r'<[^>]+>', '', song_info)
                                            song_info = re.sub(r'\s+', ' ', song_info)
                                            
                                            if (song_info and 
                                                len(song_info) > 5 and 
                                                song_info.lower() not in ['unknown', 'current song'] and
                                                not re.match(r'^\d+$', song_info)):
                                                
                                                return {
                                                    'station': station_name,
                                                    'category': category_name,
                                                    'path': station_path,
                                                    'status': 'working',
                                                    'metadata': song_info,
                                                    'method': 'radcap_station_page'
                                                }
                        except requests.RequestException:
                            continue
                            
            except requests.RequestException:
                pass
            
            return {
                'station': station_name,
                'category': category_name,
                'path': station_path,
                'status': 'failed',
                'metadata': 'No accessible metadata source found after trying all methods',
                'method': 'none'
            }
            
        except Exception as e:
            return {
                'station': station_name,
                'category': category_name,
                'path': station_path,
                'status': 'failed',
                'metadata': f'Error: {str(e)}',
                'method': 'error'
            }

    def test_somafm_station(self, station, category_name):
        """Test a SomaFM station for metadata"""
        station_name = station['name']
        station_path = station['path']
        
        try:
            # SomaFM provides track info via their songs API
            api_url = f"https://somafm.com/songs/{station_path}.json"
            response = requests.get(api_url, timeout=10)
            
            if response.status_code == 200:
                try:
                    data = response.json()
                    if data.get('songs') and len(data['songs']) > 0:
                        current_song = data['songs'][0]  # Most recent song
                        artist = current_song.get('artist', '')
                        title = current_song.get('title', '')
                        
                        if artist or title:
                            metadata = f"{artist} - {title}" if artist and title else (title or artist)
                            return {
                                'station': station_name,
                                'category': category_name,
                                'path': station_path,
                                'status': 'working',
                                'metadata': metadata,
                                'method': 'somafm_api'
                            }
                        else:
                            return {
                                'station': station_name,
                                'category': category_name,
                                'path': station_path,
                                'status': 'no_metadata',
                                'metadata': 'API response has no song data',
                                'method': 'somafm_api'
                            }
                    else:
                        return {
                            'station': station_name,
                            'category': category_name,
                            'path': station_path,
                            'status': 'no_metadata',
                            'metadata': 'API response has empty songs array',
                            'method': 'somafm_api'
                        }
                except json.JSONDecodeError:
                    return {
                        'station': station_name,
                        'category': category_name,
                        'path': station_path,
                        'status': 'failed',
                        'metadata': 'Invalid JSON response',
                        'method': 'somafm_api'
                    }
            else:
                return {
                    'station': station_name,
                    'category': category_name,
                    'path': station_path,
                    'status': 'failed',
                    'metadata': f'API returned status {response.status_code}',
                    'method': 'somafm_api'
                }
                
        except Exception as e:
            return {
                'station': station_name,
                'category': category_name,
                'path': station_path,
                'status': 'failed',
                'metadata': f'Error: {str(e)}',
                'method': 'error'
            }

    def test_station_worker(self, args):
        """Worker function for threading"""
        station, category_name, source_type, index, total = args
        
        # Update progress
        with self.lock:
            self.print_progress(index + 1, total, station['name'])
        
        if source_type == 'radcap':
            result = self.test_radcap_station(station, category_name)
        else:  # somafm
            result = self.test_somafm_station(station, category_name)
        
        # Store result
        with self.lock:
            self.results[result['status']].append(result)
            self.results['total_tested'] += 1
        
        return result

    def load_radio_data(self):
        """Load radio data from radiodata.js file"""
        try:
            radiodata_path = '/home/user/Documents/Free-Radio-NoAds-NoTalk/radcapradio/contents/ui/radiodata.js'
            print(f"Attempting to load radio data from: {radiodata_path}")
            
            with open(radiodata_path, 'r') as f:
                content = f.read()
            
            print(f"File loaded successfully, content length: {len(content)} characters")
            
            # Extract RadCap categories with more robust regex
            radcap_match = re.search(r'var radcapCategories = (\[.*?\n\])', content, re.DOTALL | re.MULTILINE)
            somafm_match = re.search(r'var somafmCategories = (\[.*?\n\])', content, re.DOTALL | re.MULTILINE)
            
            if radcap_match:
                print(f"Found RadCap data, length: {len(radcap_match.group(1))}")
                try:
                    # Clean up JavaScript to make it valid JSON
                    radcap_js = radcap_match.group(1)
                    # Remove trailing commas before closing braces/brackets
                    radcap_js = re.sub(r',(\s*[}\]])', r'\1', radcap_js)
                    radcap_data = json.loads(radcap_js)
                    print(f"Parsed {len(radcap_data)} RadCap categories")
                except json.JSONDecodeError as e:
                    print(f"Error parsing RadCap JSON: {e}")
                    print("RadCap data preview:", radcap_match.group(1)[:300])
                    # Try to extract at least some basic station info manually
                    radcap_data = self._manual_parse_radcap(radcap_match.group(1))
            else:
                print("No RadCap data found in file")
                radcap_data = []
                
            if somafm_match:
                print(f"Found SomaFM data, length: {len(somafm_match.group(1))}")
                try:
                    # Clean up JavaScript to make it valid JSON
                    somafm_js = somafm_match.group(1)
                    # Remove trailing commas before closing braces/brackets
                    somafm_js = re.sub(r',(\s*[}\]])', r'\1', somafm_js)
                    somafm_data = json.loads(somafm_js)
                    print(f"Parsed {len(somafm_data)} SomaFM categories")
                except json.JSONDecodeError as e:
                    print(f"Error parsing SomaFM JSON: {e}")
                    print("SomaFM data preview:", somafm_match.group(1)[:200])
                    somafm_data = []
            else:
                print("No SomaFM data found in file")
                somafm_data = []
            
            return radcap_data, somafm_data
            
        except Exception as e:
            print(f"Error loading radio data: {e}")
            import traceback
            traceback.print_exc()
            return [], []
    
    def _manual_parse_radcap(self, js_content):
        """Manually parse RadCap stations if JSON parsing fails"""
        print("Attempting manual parsing of RadCap data...")
        categories = []
        try:
            # Extract station entries using regex
            station_pattern = r'\{\s*"name"\s*:\s*"([^"]+)"\s*,\s*"host"\s*:\s*"([^"]+)"\s*,\s*"path"\s*:\s*"([^"]+)"\s*\}'
            stations = re.findall(station_pattern, js_content)
            
            if stations:
                # Create a single category with all found stations
                categories.append({
                    "name": "All RadCap Stations",
                    "stations": [{"name": name, "host": host, "path": path} for name, host, path in stations]
                })
                print(f"Manual parsing found {len(stations)} RadCap stations")
            
        except Exception as e:
            print(f"Manual parsing failed: {e}")
        
        return categories

    def run_tests(self, max_workers=10):
        """Run metadata tests on all stations"""
        print("Loading radio station data...")
        radcap_categories, somafm_categories = self.load_radio_data()
        
        if not radcap_categories and not somafm_categories:
            print("No radio data found!")
            return
        
        # Prepare test tasks
        tasks = []
        
        # Add RadCap stations
        for category in radcap_categories:
            for station in category.get('stations', []):
                tasks.append((station, category['name'], 'radcap'))
        
        # Add SomaFM stations
        for category in somafm_categories:
            for station in category.get('stations', []):
                tasks.append((station, category['name'], 'somafm'))
        
        total_stations = len(tasks)
        print(f"Testing metadata for {total_stations} stations...")
        print("This may take several minutes...\n")
        
        # Add index and total to each task
        indexed_tasks = [(task[0], task[1], task[2], i, total_stations) for i, task in enumerate(tasks)]
        
        # Run tests with threading
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            list(executor.map(self.test_station_worker, indexed_tasks))
        
        print("\n\nTesting complete!")

    def print_results(self):
        """Print detailed results"""
        print(f"\n{'='*80}")
        print("METADATA TEST RESULTS")
        print(f"{'='*80}")
        
        print(f"\nSUMMARY:")
        print(f"Total stations tested: {self.results['total_tested']}")
        print(f"✅ Working metadata: {len(self.results['working'])} ({len(self.results['working'])/self.results['total_tested']*100:.1f}%)")
        print(f"❌ No metadata: {len(self.results['no_metadata'])} ({len(self.results['no_metadata'])/self.results['total_tested']*100:.1f}%)")
        print(f"💥 Failed to test: {len(self.results['failed'])} ({len(self.results['failed'])/self.results['total_tested']*100:.1f}%)")
        
        # Show stations with working metadata
        if self.results['working']:
            print(f"\n{'='*80}")
            print("✅ STATIONS WITH WORKING METADATA:")
            print(f"{'='*80}")
            for result in sorted(self.results['working'], key=lambda x: x['category']):
                print(f"📻 {result['station']} ({result['category']})")
                print(f"   Current: {result['metadata']}")
                print(f"   Method: {result['method']}")
                print()
        
        # Show stations without metadata
        if self.results['no_metadata']:
            print(f"\n{'='*80}")
            print("❌ STATIONS WITHOUT METADATA:")
            print(f"{'='*80}")
            for result in sorted(self.results['no_metadata'], key=lambda x: x['category']):
                print(f"📻 {result['station']} ({result['category']})")
                print(f"   Issue: {result['metadata']}")
                print(f"   Path: {result['path']}")
                print()
        
        # Show failed stations
        if self.results['failed']:
            print(f"\n{'='*80}")
            print("💥 FAILED TO TEST:")
            print(f"{'='*80}")
            for result in sorted(self.results['failed'], key=lambda x: x['category']):
                print(f"📻 {result['station']} ({result['category']})")
                print(f"   Error: {result['metadata']}")
                print(f"   Path: {result['path']}")
                print()

    def save_results(self, filename='station_metadata_test_results.json'):
        """Save results to JSON file"""
        with open(filename, 'w') as f:
            json.dump(self.results, f, indent=2)
        print(f"Results saved to {filename}")

def main():
    if len(sys.argv) > 1 and sys.argv[1] in ['-h', '--help']:
        print("Usage: python3 test_station_metadata.py [max_workers]")
        print("Tests all radio stations for song title metadata availability")
        print("max_workers: Number of concurrent connections (default: 10)")
        return
    
    max_workers = 10
    if len(sys.argv) > 1:
        try:
            max_workers = int(sys.argv[1])
        except ValueError:
            print("Invalid max_workers value, using default of 10")
    
    checker = MetadataChecker()
    
    try:
        checker.run_tests(max_workers=max_workers)
        checker.print_results()
        checker.save_results()
        
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        checker.print_results()
        checker.save_results('partial_station_metadata_test_results.json')
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        if checker.results['total_tested'] > 0:
            checker.print_results()
            checker.save_results('error_station_metadata_test_results.json')

if __name__ == "__main__":
    main()