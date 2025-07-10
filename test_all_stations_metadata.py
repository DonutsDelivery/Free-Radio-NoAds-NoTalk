#!/usr/bin/env python3

import json
import requests
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

def test_server_metadata(server_url, station_path):
    """Test if we can get metadata from the server for a specific station"""
    try:
        # Only 79.111.119.111:8000 has working metadata
        if "79.111.119.111:8000" not in server_url:
            return False, "Server doesn't provide metadata"
            
        response = requests.get(server_url, timeout=10)
        if response.status_code == 200:
            content = response.text
            
            # Look for the specific mount point
            mount_pattern = rf'<h3>Mount Point /{re.escape(station_path)}</h3>.*?<td class="streamdata">([^<]+)</td>'
            match = re.search(mount_pattern, content, re.DOTALL | re.IGNORECASE)
            
            if match:
                song_info = match.group(1).strip()
                return True, song_info
            else:
                return False, "Mount point not found"
        else:
            return False, f"HTTP {response.status_code}"
    except Exception as e:
        return False, str(e)

def test_playback_history(station_path):
    """Test if we can get metadata from playback history (fallback method)"""
    
    # Path mappings
    path_mappings = {
        "musicgame": "gamemusic",
        "indianfolk": "indian",
        "nativeamerican": "natam",
        "slavonicneofolk": "slavonic",
        "classpiano": "classicalpiano",
        "popballads": "popball",
        "mainstreamjazz": "jazz",
        "jazzfusion": "fusion",
        "mcreative": "moderncreative",
        "ecmrecords": "ecm",
        "trumpetjazz": "trumpet",
        "bardru": "bard",
        "frenchchanson": "chanson",
        "tradpop": "pop",
        "cpop": "cantopop",
        "harpblues": "harp",
        "chorus": "choral",
        "chants": "chant"
    }
    
    metadata_path = path_mappings.get(station_path, station_path)
    
    # Try different path numbers
    for path_num in [1, 2, 3, 4, 5, 6]:
        try:
            url = f"http://radcap.ru/playback-history/{path_num}/{metadata_path}-ph.php"
            response = requests.get(url, timeout=8)
            
            if response.status_code == 200:
                content = response.text.lower()
                
                # Skip 404 pages
                if any(error_text in content for error_text in [
                    'запрашиваемая страница на сайте отсутствует', 
                    '404', 'not found', 'page not found'
                ]):
                    continue
                
                # Check for actual content
                if any(keyword in content for keyword in [
                    '<td>', 'playback', 'history', 'current song', 'artist', 'title',
                    'radcap', 'channel:', 'now playing'
                ]) and 'html' in content:
                    return True, f"Path {path_num} working"
                    
        except Exception:
            continue
    
    return False, "No working paths found"

def test_station_metadata_comprehensive(station_name, station_path, server_url):
    """Test both server and fallback methods for a station"""
    
    # First try server-based metadata
    server_success, server_result = test_server_metadata(server_url, station_path)
    
    if server_success:
        return {
            'station': station_name,
            'path': station_path,
            'server': server_url,
            'method': 'server',
            'status': 'working',
            'metadata': server_result,
            'fallback_available': None
        }
    
    # If server failed, try playback history fallback
    fallback_success, fallback_result = test_playback_history(station_path)
    
    return {
        'station': station_name,
        'path': station_path,
        'server': server_url,
        'method': 'fallback' if fallback_success else 'failed',
        'status': 'working' if fallback_success else 'failed',
        'metadata': fallback_result,
        'fallback_available': fallback_success
    }

def main():
    print("Testing metadata coverage for ALL radio stations...")
    print("=" * 80)
    
    # Load server mapping
    with open('server_metadata_mapping.json', 'r') as f:
        server_mapping = json.load(f)
    
    # Load station names from radiodata.js
    try:
        with open('radcapradio/contents/ui/radiodata.js', 'r') as f:
            radiodata_content = f.read()
            
        # Extract station info (this is a simplified approach)
        # In reality, we'd need to parse the JS properly
        stations_to_test = []
        
        for path, server in server_mapping['path_to_server'].items():
            # Create a representative station name
            station_name = path.replace('_', ' ').title()
            stations_to_test.append((station_name, path, server))
        
    except Exception as e:
        print(f"Could not load radiodata.js: {e}")
        print("Using server mapping data directly...")
        
        stations_to_test = []
        for path, server in server_mapping['path_to_server'].items():
            station_name = path.replace('_', ' ').title()
            stations_to_test.append((station_name, path, server))
    
    print(f"Testing {len(stations_to_test)} stations...")
    
    results = []
    server_metadata_count = 0
    fallback_metadata_count = 0
    failed_count = 0
    
    # Test stations (with rate limiting)
    for i, (station_name, station_path, server_url) in enumerate(stations_to_test):
        if i % 10 == 0:
            print(f"Progress: {i}/{len(stations_to_test)} ({i/len(stations_to_test)*100:.1f}%)")
        
        result = test_station_metadata_comprehensive(station_name, station_path, server_url)
        results.append(result)
        
        if result['status'] == 'working':
            if result['method'] == 'server':
                server_metadata_count += 1
            else:
                fallback_metadata_count += 1
        else:
            failed_count += 1
        
        # Rate limiting
        time.sleep(0.1)
    
    # Calculate statistics
    total_working = server_metadata_count + fallback_metadata_count
    coverage_percent = (total_working / len(stations_to_test)) * 100
    
    print("\n" + "=" * 80)
    print("COMPREHENSIVE METADATA TESTING RESULTS")
    print("=" * 80)
    
    print(f"\n📊 COVERAGE STATISTICS:")
    print(f"  • Total stations tested: {len(stations_to_test)}")
    print(f"  • Server-based metadata: {server_metadata_count}")
    print(f"  • Fallback metadata: {fallback_metadata_count}")
    print(f"  • Total working: {total_working}")
    print(f"  • Failed: {failed_count}")
    print(f"  • Coverage: {coverage_percent:.1f}%")
    
    # Show working server metadata stations
    server_working = [r for r in results if r['method'] == 'server']
    if server_working:
        print(f"\n✅ SERVER METADATA WORKING ({len(server_working)} stations):")
        for result in server_working[:10]:  # Show first 10
            print(f"  • {result['station']}: {result['metadata'][:60]}...")
        if len(server_working) > 10:
            print(f"  ... and {len(server_working) - 10} more")
    
    # Show failed stations
    failed_stations = [r for r in results if r['status'] == 'failed']
    if failed_stations:
        print(f"\n❌ FAILED STATIONS ({len(failed_stations)}):")
        for result in failed_stations[:20]:  # Show first 20
            print(f"  • {result['station']} ({result['path']}): {result['metadata']}")
        if len(failed_stations) > 20:
            print(f"  ... and {len(failed_stations) - 20} more")
    
    # Save detailed results
    with open('comprehensive_metadata_test_results.json', 'w') as f:
        json.dump({
            'statistics': {
                'total_stations': len(stations_to_test),
                'server_metadata': server_metadata_count,
                'fallback_metadata': fallback_metadata_count,
                'total_working': total_working,
                'failed': failed_count,
                'coverage_percent': coverage_percent
            },
            'results': results
        }, f, indent=2)
    
    print(f"\n💾 Detailed results saved to: comprehensive_metadata_test_results.json")
    
    if coverage_percent >= 90:
        print(f"\n🎉 EXCELLENT! {coverage_percent:.1f}% metadata coverage achieved!")
    elif coverage_percent >= 75:
        print(f"\n✅ GOOD! {coverage_percent:.1f}% metadata coverage achieved!")
    else:
        print(f"\n⚠️  Coverage at {coverage_percent:.1f}% - room for improvement")

if __name__ == "__main__":
    main()