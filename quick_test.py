#\!/usr/bin/env python3
"""
Quick test of specific RadCap stations including the video game music station
"""

import requests
import re

def test_radcap_station(station_name, station_path, host):
    """Test a specific RadCap station for metadata"""
    print(f"\n🎵 Testing: {station_name}")
    print(f"   Path: {station_path}")
    print(f"   Host: {host}")
    
    try:
        # Try multiple possible HTML page names
        possible_names = [station_path, "videogame", "gamemusic", "vgmusic"]
        
        for page_name in possible_names:
            try:
                station_url = f"http://radcap.ru/{page_name}.html"
                print(f"   Trying: {station_url}")
                response = requests.get(station_url, timeout=10)
                
                if response.status_code == 200:
                    print("   ✅ Station page found\!")
                    
                    # Look for playback-html link
                    playback_match = re.search(r'class="playback-html"[^>]*>\s*<a\s+href="([^"]+)"', response.text, re.IGNORECASE)
                    
                    if playback_match:
                        playback_path = playback_match.group(1)
                        playback_url = f"http://radcap.ru/{playback_path}"
                        print(f"   📊 Playback URL: {playback_url}")
                        
                        # Fetch playback history
                        playback_response = requests.get(playback_url, timeout=10)
                        
                        if playback_response.status_code == 200:
                            print("   ✅ Playback history accessible\!")
                            
                            # Try to find current song
                            patterns = [
                                r'<td>([^<]+)<td><b>Current Song</b></td>',
                                r'<td>([^<]+)</td><td><b>Current Song</b></td>',
                                r'<td>\d{2}:\d{2}:\d{2}</td><td>([^<]+)(?:<td> < /dev/null | </td>)'
                            ]
                            
                            song_found = False
                            for pattern in patterns:
                                match = re.search(pattern, playback_response.text, re.IGNORECASE)
                                if match:
                                    song_info = match.group(1).strip()
                                    if song_info and song_info != "Unknown" and len(song_info) > 3:
                                        print(f"   🎶 Current song: {song_info}")
                                        return "working"
                                    else:
                                        print(f"   ❌ Empty/generic metadata: '{song_info}'")
                                        return "no_metadata"
                                    song_found = True
                                    break
                            
                            if not song_found:
                                print("   ❌ No song data found in playback history")
                                # Show a sample of the HTML for debugging
                                print("   📄 HTML preview:")
                                lines = playback_response.text.split('\n')[:10]
                                for line in lines:
                                    if line.strip():
                                        print(f"      {line.strip()[:100]}")
                            return "no_metadata"
                        else:
                            print(f"   ❌ Playback history failed: {playback_response.status_code}")
                    else:
                        print("   ❌ No playback link found on station page")
                    break
                elif response.status_code == 404:
                    print(f"   ❌ Not found: {station_url}")
                    continue
                else:
                    print(f"   ❌ Error {response.status_code}: {station_url}")
                    
            except requests.RequestException as e:
                print(f"   ❌ Request failed for {page_name}: {e}")
                continue
        
        # Try fallback method with path numbers
        print("   🔄 Trying fallback method...")
        for path_num in [2, 3, 4, 1, 5, 6]:
            try:
                fallback_url = f"http://radcap.ru/playback-history/{path_num}/{station_path}-ph.php"
                print(f"   Trying fallback: {fallback_url}")
                response = requests.get(fallback_url, timeout=10)
                
                if response.status_code == 200:
                    print(f"   ✅ Fallback path {path_num} works\!")
                    patterns = [
                        r'<td>([^<]+)<td><b>Current Song</b></td>',
                        r'<td>([^<]+)</td><td><b>Current Song</b></td>',
                        r'<td>\d{2}:\d{2}:\d{2}</td><td>([^<]+)(?:<td>|</td>)'
                    ]
                    
                    for pattern in patterns:
                        match = re.search(pattern, response.text, re.IGNORECASE)
                        if match:
                            song_info = match.group(1).strip()
                            if song_info and song_info != "Unknown" and len(song_info) > 3:
                                print(f"   🎶 Current song: {song_info}")
                                return "working"
                            else:
                                print(f"   ❌ Empty/generic metadata: '{song_info}'")
                                return "no_metadata"
                    break
                    
            except requests.RequestException:
                continue
        
        print("   💥 All methods failed")
        return "failed"
        
    except Exception as e:
        print(f"   💥 Error: {e}")
        return "failed"

def main():
    # Test specific stations including the problematic video game music station
    test_stations = [
        ("Computer / Video Game Music", "musicgame", "http://79.120.39.202"),
        ("Classical Piano", "classpiano", "http://79.111.14.76"),
        ("Jazz", "jazz", "http://79.111.14.76"),
        ("Alternative Rock", "altrock", "http://79.111.14.76"),
        ("Blues", "blues", "http://79.111.14.76")
    ]
    
    print("🧪 Quick Test of RadCap Station Metadata")
    print("=" * 50)
    
    results = {"working": 0, "no_metadata": 0, "failed": 0}
    
    for station_name, station_path, host in test_stations:
        result = test_radcap_station(station_name, station_path, host)
        results[result] += 1
    
    print("\n" + "=" * 50)
    print("📊 QUICK TEST RESULTS:")
    print(f"✅ Working metadata: {results['working']}")
    print(f"❌ No metadata: {results['no_metadata']}")
    print(f"💥 Failed to test: {results['failed']}")
    
    if results['no_metadata'] > 0 or results['failed'] > 0:
        print("\n⚠️  Some stations don't provide metadata or failed to test")
        print("This is expected for some RadCap stations as not all provide real-time song data")

if __name__ == "__main__":
    main()
