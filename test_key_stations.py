#!/usr/bin/env python3

import requests
import json

def test_metadata_url(url, timeout=10):
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
                return True, response.text[:200]
        return False, f"Status: {response.status_code}"
    except Exception as e:
        return False, str(e)

def test_station_metadata(station_name, station_path, test_paths=[1,2,3,4,5,6]):
    """Test metadata for a specific station"""
    print(f"\nTesting: {station_name} (path: {station_path})")
    
    # Test original path
    print(f"  Testing original path '{station_path}':")
    for path_num in test_paths:
        url = f"http://radcap.ru/playback-history/{path_num}/{station_path}-ph.php"
        success, content = test_metadata_url(url)
        print(f"    Path {path_num}: {'✓' if success else '✗'} {url}")
        if success:
            print(f"      Content preview: {content[:100]}...")
            return True, url
    
    # Test gamemusic for musicgame
    if station_path == "musicgame":
        print(f"  Testing alternative path 'gamemusic':")
        for path_num in test_paths:
            url = f"http://radcap.ru/playback-history/{path_num}/gamemusic-ph.php"
            success, content = test_metadata_url(url)
            print(f"    Path {path_num}: {'✓' if success else '✗'} {url}")
            if success:
                print(f"      Content preview: {content[:100]}...")
                return True, url
    
    return False, None

def main():
    # Test stations that should now be fixed
    key_stations = [
        # Previously fixed
        ("Computer / Video Game Music", "musicgame"),
        # Should be fixed with new mappings
        ("Indian Classical / Folk / Ethnic", "indianfolk"),
        ("Native American", "nativeamerican"),
        ("Slavonic Neofolk", "slavonicneofolk"),
        ("Classical Piano", "classpiano"),
        ("Pop Ballads", "popballads"),
        ("Mainstream Jazz", "mainstreamjazz"),
        ("Jazz Fusion", "jazzfusion"),
        ("ECM Records", "ecmrecords"),
        ("Jazz Trumpet", "trumpetjazz"),
        ("French Chanson", "frenchchanson"),
        ("Traditional Pop", "tradpop"),
        ("C-Pop", "cpop"),
        ("Harmonica Blues", "harpblues"),
        ("Choral Music", "chorus"),
        ("Chants", "chants"),
        # Should still work
        ("Tango", "tango"),
        ("Blues", "blues"),
        ("Jazz", "jazz")
    ]
    
    print("Testing key stations for metadata fetching...")
    print("=" * 60)
    
    working = []
    failed = []
    
    for station_name, station_path in key_stations:
        success, url = test_station_metadata(station_name, station_path)
        if success:
            working.append((station_name, url))
        else:
            failed.append((station_name, station_path))
    
    print("\n" + "=" * 60)
    print("RESULTS SUMMARY")
    print("=" * 60)
    
    print(f"\n✓ WORKING STATIONS ({len(working)}):")
    for name, url in working:
        print(f"  • {name}")
        print(f"    {url}")
    
    print(f"\n✗ FAILED STATIONS ({len(failed)}):")
    for name, path in failed:
        print(f"  • {name} (path: {path})")
    
    print(f"\nSuccess rate: {len(working)}/{len(key_stations)} ({len(working)/len(key_stations)*100:.1f}%)")

if __name__ == "__main__":
    main()