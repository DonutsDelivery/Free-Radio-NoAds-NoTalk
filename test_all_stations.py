#!/usr/bin/env python3
"""
Script to test song title fetching for all RadCap radio stations.
This will help identify which stations work and which need fixes.
"""

import json
import requests
import re
import time
from urllib.parse import urlparse

def load_station_data():
    """Load station data from JSON file"""
    try:
        # Use the existing JSON data file
        json_paths = [
            'radcap channels/full_named_streams.json',
            './radcap channels/full_named_streams.json',
            '/home/user/Documents/Free-Radio-NoAds-NoTalk/radcap channels/full_named_streams.json'
        ]
        
        for path in json_paths:
            try:
                with open(path, 'r') as f:
                    stations_data = json.load(f)
                    print(f"Loaded station data from: {path}")
                    
                    # Convert to the format expected by our script
                    # Group stations by category (we'll create a simple category for all)
                    categories = [{
                        "name": "ALL STATIONS",
                        "stations": []
                    }]
                    
                    for i, station in enumerate(stations_data):
                        try:
                            # Extract host and path from URL
                            url = station["url"]
                            name = station["name"]
                            
                            # Parse URL like "http://79.111.14.76:8002/undergroundrap"
                            parts = url.split("/")
                            if len(parts) >= 4:
                                host_port = "/".join(parts[:3])  # "http://79.111.14.76:8002"
                                path = parts[3]  # "undergroundrap"
                                
                                # Convert to format expected by test
                                host = host_port.replace(":8002", "").replace(":8004", "")  # Remove non-standard ports
                                
                                categories[0]["stations"].append({
                                    "name": name,
                                    "host": host,
                                    "path": path
                                })
                        except KeyError as e:
                            print(f"Error processing station {i}: missing key {e}")
                            print(f"Station data: {station}")
                        except Exception as e:
                            print(f"Error processing station {i}: {e}")
                            print(f"Station data: {station}")
                    
                    print(f"Loaded {len(categories[0]['stations'])} stations")
                    return categories
                    
            except FileNotFoundError:
                continue
        
        print("Could not find station data file")
        return []
    except Exception as e:
        print(f"Error loading station data: {e}")
        return []

def get_stream_url(host, path, quality="2"):
    """Convert host/path to stream URL with quality"""
    # Quality mapping (same as in QML)
    port_map = {"1": "8002", "2": "8000", "3": "8004"}
    port = port_map.get(quality, "8000")
    
    # Replace port in host URL
    base_url = host.replace(":8000", f":{port}")
    if not base_url.endswith(f":{port}"):
        base_url += f":{port}"
    
    return f"{base_url}/{path}"

def try_playback_history_url(station_path, possible_names):
    """Try to fetch song info from playback history URLs"""
    path_numbers = [2, 3, 4, 1, 5, 6]
    
    for name in possible_names:
        for path_num in path_numbers:
            url = f"http://radcap.ru/playback-history/{path_num}/{name}-ph.php"
            try:
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    # Try multiple regex patterns to find current song
                    patterns = [
                        r'<td>([^<]+)<td><b>Current Song</b></td>',
                        r'<td>([^<]+)</td><td><b>Current Song</b></td>',
                        r'<td>\d{2}:\d{2}:\d{2}</td><td>([^<]+)(?:<td>|</td>)'
                    ]
                    
                    for pattern in patterns:
                        match = re.search(pattern, response.text, re.IGNORECASE)
                        if match:
                            song_info = match.group(1).strip()
                            if song_info and song_info != "":
                                return {
                                    "success": True,
                                    "song": song_info,
                                    "method": f"playback-history/{path_num}/{name}-ph.php",
                                    "url": url
                                }
            except Exception as e:
                continue
    
    return {"success": False, "error": "No valid playback history URL found"}

def try_station_page_url(station_path, possible_names):
    """Try to get playback history URL from station main page"""
    for name in possible_names:
        try:
            url = f"http://radcap.ru/{name}.html"
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                # Look for playback-html class link
                match = re.search(r'class="playback-html"[^>]*>\s*<a\s+href="([^"]+)"', response.text, re.IGNORECASE)
                if match:
                    playback_path = match.group(1)
                    playback_url = f"http://radcap.ru/{playback_path}"
                    
                    # Fetch the playback history
                    try:
                        pb_response = requests.get(playback_url, timeout=10)
                        if pb_response.status_code == 200:
                            patterns = [
                                r'<td>([^<]+)<td><b>Current Song</b></td>',
                                r'<td>([^<]+)</td><td><b>Current Song</b></td>',
                                r'<td>\d{2}:\d{2}:\d{2}</td><td>([^<]+)(?:<td>|</td>)'
                            ]
                            
                            for pattern in patterns:
                                match = re.search(pattern, pb_response.text, re.IGNORECASE)
                                if match:
                                    song_info = match.group(1).strip()
                                    if song_info and song_info != "":
                                        return {
                                            "success": True,
                                            "song": song_info,
                                            "method": f"station-page->{playback_path}",
                                            "url": playback_url
                                        }
                    except Exception as e:
                        continue
        except Exception as e:
            continue
    
    return {"success": False, "error": "No valid station page found"}

def get_naming_variations(station_path):
    """Get possible naming variations for a station (same logic as QML)"""
    variations = [station_path]
    
    # Add variations based on the QML code
    naming_map = {
        "classpiano": ["classicalpiano"],
        "indianfolk": ["indian", "indianclassical"],
        "folkrockru": ["folkrockru", "russianfolk", "folkrock"],
        "symphony": ["symphonic"],
        "nativeamerican": ["natam"],
        "celticrock": ["celtic", "celticrock"],
        "middleeast": ["middleeast"],
        "symphorock": ["symphonic", "symphorock"],
        "chorus": ["choral", "chorus"],
        "organ": ["organ"],
        "baroque": ["baroque"],
        "opera": ["opera"],
        "strings": ["strings"],
        "contclass": ["contclass", "modernclassical"],
        "renaissance": ["renaissance"],
        "medieval": ["medieval"],
        "chamber": ["chamber"]
    }
    
    if station_path in naming_map:
        variations.extend(naming_map[station_path])
    
    return variations

def test_station(station_name, host, path):
    """Test song fetching for a single station"""
    print(f"\n--- Testing: {station_name} ---")
    print(f"Stream path: {path}")
    print(f"Host: {host}")
    
    # Get naming variations
    variations = get_naming_variations(path)
    print(f"Trying variations: {variations}")
    
    # Try station page method first
    result = try_station_page_url(path, variations)
    if result["success"]:
        print(f"✅ SUCCESS via station page: {result['song']}")
        print(f"   Method: {result['method']}")
        return {"station": station_name, "path": path, "status": "success", "song": result["song"], "method": result["method"]}
    
    # Try playback history method
    result = try_playback_history_url(path, variations)
    if result["success"]:
        print(f"✅ SUCCESS via playback history: {result['song']}")
        print(f"   Method: {result['method']}")
        return {"station": station_name, "path": path, "status": "success", "song": result["song"], "method": result["method"]}
    
    print(f"❌ FAILED: {result['error']}")
    return {"station": station_name, "path": path, "status": "failed", "error": result["error"]}

def main():
    print("🎵 Testing RadCap Radio Stations Song Fetching 🎵")
    print("=" * 60)
    
    categories = load_station_data()
    if not categories:
        print("Failed to load station data!")
        return
    
    all_results = []
    total_stations = 0
    successful_stations = 0
    
    for category in categories:
        print(f"\n📻 Category: {category['name']}")
        print("-" * 40)
        
        for station in category['stations']:
            total_stations += 1
            result = test_station(station['name'], station['host'], station['path'])
            all_results.append(result)
            
            if result['status'] == 'success':
                successful_stations += 1
            
            # Small delay to be nice to the server
            time.sleep(0.5)
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 SUMMARY")
    print("=" * 60)
    print(f"Total stations tested: {total_stations}")
    print(f"Successful: {successful_stations}")
    print(f"Failed: {total_stations - successful_stations}")
    print(f"Success rate: {(successful_stations/total_stations)*100:.1f}%")
    
    # Failed stations
    failed_stations = [r for r in all_results if r['status'] == 'failed']
    if failed_stations:
        print(f"\n❌ Failed stations ({len(failed_stations)}):")
        for station in failed_stations:
            print(f"   • {station['station']} (path: {station['path']})")
    
    # Save detailed results
    with open('station_test_results.json', 'w') as f:
        json.dump(all_results, f, indent=2)
    
    print(f"\n💾 Detailed results saved to: station_test_results.json")

if __name__ == "__main__":
    main()