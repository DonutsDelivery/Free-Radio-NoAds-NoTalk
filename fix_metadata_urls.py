#!/usr/bin/env python3

import json
import requests
import time
import re

def test_metadata_url(url, timeout=5):
    """Test if a URL returns valid metadata"""
    try:
        response = requests.get(url, timeout=timeout, headers={
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        })
        if response.status_code == 200:
            content = response.text.lower()
            
            # Skip 404 pages even if they return 200 status
            if 'запрашиваемая страница на сайте отсутствует' in content or '404' in content:
                return False, "404 page content"
            
            # Check for song information patterns
            if any(keyword in content for keyword in [
                'current song', 'now playing', 'song', 'artist', 'title',
                'currently playing', 'on air', 'track', 'радиокапель',
                '<td>', 'playback', 'history'
            ]):
                return True, response.text[:300]
        return False, f"Status: {response.status_code}"
    except Exception as e:
        return False, str(e)

def get_failed_stations():
    """Get failed stations from existing results"""
    try:
        with open('station_metadata_test_results.json', 'r') as f:
            data = json.load(f)
        return [s for s in data.get('failed', []) if s.get('status') == 'failed']
    except:
        return []

def test_additional_patterns(station_path):
    """Test additional metadata URL patterns for a station"""
    
    # Known working patterns from successful stations
    patterns = [
        # Direct playback history URLs with different path numbers
        f"http://radcap.ru/playback-history/1/{station_path}-ph.php",
        f"http://radcap.ru/playback-history/2/{station_path}-ph.php", 
        f"http://radcap.ru/playback-history/3/{station_path}-ph.php",
        f"http://radcap.ru/playback-history/4/{station_path}-ph.php",
        f"http://radcap.ru/playback-history/5/{station_path}-ph.php",
        f"http://radcap.ru/playback-history/6/{station_path}-ph.php",
        f"http://radcap.ru/playback-history/7/{station_path}-ph.php",
        
        # Alternative naming patterns based on working stations
        f"http://radcap.ru/playback-history/2/{station_path.replace('musicgame', 'gamemusic')}-ph.php",
        f"http://radcap.ru/playback-history/3/{station_path.replace('musicgame', 'gamemusic')}-ph.php",
        f"http://radcap.ru/playback-history/2/{station_path.replace('musicgame', 'games')}-ph.php",
        f"http://radcap.ru/playback-history/2/{station_path.replace('musicgame', 'videogames')}-ph.php",
        
        # Try shortening some long paths
        f"http://radcap.ru/playback-history/2/{station_path[:8]}-ph.php",
        f"http://radcap.ru/playback-history/3/{station_path[:8]}-ph.php",
        
        # Try different formats
        f"http://radcap.ru/playback-history/2/{station_path}.php",
        f"http://radcap.ru/playback-history/3/{station_path}.php",
    ]
    
    working_urls = []
    for url in patterns:
        print(f"  Testing: {url}")
        success, content = test_metadata_url(url)
        if success:
            working_urls.append({
                'url': url,
                'content_preview': content
            })
            print(f"  ✓ SUCCESS!")
            break  # Found working URL, no need to test more
        time.sleep(0.3)  # Rate limiting
    
    return working_urls

def main():
    print("Loading failed stations...")
    failed_stations = get_failed_stations()
    
    if not failed_stations:
        print("No failed stations found in results file.")
        return
    
    print(f"Found {len(failed_stations)} failed stations")
    
    # Test the video game music station specifically first
    target_stations = []
    
    # Find video game music station
    for station in failed_stations:
        if station.get('path') == 'musicgame':
            target_stations.append(station)
            break
    
    # Add a few more failed stations for testing
    other_failed = [s for s in failed_stations if s.get('path') != 'musicgame'][:5]
    target_stations.extend(other_failed)
    
    print(f"Testing {len(target_stations)} stations...")
    
    fixes = []
    for i, station in enumerate(target_stations):
        station_name = station.get('station', 'Unknown')
        station_path = station.get('path', '')
        
        print(f"\n[{i+1}/{len(target_stations)}] Testing: {station_name}")
        print(f"  Path: {station_path}")
        
        if station_path:
            working_urls = test_additional_patterns(station_path)
            
            if working_urls:
                fix = {
                    'station': station_name,
                    'path': station_path,
                    'category': station.get('category'),
                    'working_metadata_url': working_urls[0]['url'],
                    'content_preview': working_urls[0]['content_preview']
                }
                fixes.append(fix)
                print(f"  ✓ FIXED with: {working_urls[0]['url']}")
            else:
                print(f"  ✗ No working metadata URL found")
        else:
            print(f"  ✗ No path available")
    
    if fixes:
        # Save the fixes
        with open('metadata_url_fixes.json', 'w') as f:
            json.dump(fixes, f, indent=2)
        
        print(f"\n✓ Found working metadata URLs for {len(fixes)} stations!")
        print("Fixes saved to metadata_url_fixes.json")
        
        for fix in fixes:
            print(f"  {fix['station']}: {fix['working_metadata_url']}")
            
    else:
        print("\n✗ No fixes found for any stations")

if __name__ == "__main__":
    main()